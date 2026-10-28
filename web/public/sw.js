/* Remember stores personal data in IndexedDB. This worker caches only public app files. */
const CACHE_VERSION = "remember-v1";
const SHELL_CACHE = `${CACHE_VERSION}-shell`;
const PAGE_CACHE = `${CACHE_VERSION}-pages`;
const ASSET_CACHE = `${CACHE_VERSION}-assets`;
const CACHE_PREFIX = "remember-";
const MAX_ASSETS = 120;
const PRECACHE = [
  "/offline.html",
  "/manifest.webmanifest",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/apple-touch-icon.png",
  "/icons/favicon.png",
  "/apple-touch-icon.png",
  "/favicon.ico",
];

self.addEventListener("install", (event) => {
  event.waitUntil((async () => {
    const shell = await caches.open(SHELL_CACHE);
    await shell.addAll(PRECACHE);
    // Cache the entry document, but do not make a temporary server error block installation.
    try {
      const response = await fetch("/", { cache: "reload" });
      if (response.ok) {
        const html = await response.clone().text();
        const pages = await caches.open(PAGE_CACHE);
        await pages.put("/", response);
        // The initial page loads its JS/CSS before this worker takes control.
        // Precache assets named by that document so its very next load works offline.
        const assetURLs = new Set();
        for (const [, value] of html.matchAll(/(?:src|href)="([^"]+)"/g)) {
          try {
            const assetURL = new URL(value, self.location.origin);
            if (assetURL.origin === self.location.origin && assetURL.pathname.startsWith("/_next/static/")) {
              assetURLs.add(assetURL.href);
            }
          } catch {
            // Ignore malformed or non-URL attributes in the generated document.
          }
        }
        const assets = await caches.open(ASSET_CACHE);
        await Promise.allSettled([...assetURLs].map((url) => assets.add(url)));
      }
    } catch {
      // The offline document remains available when the entry page cannot be fetched.
    }
  })());
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((name) => name.startsWith(CACHE_PREFIX)
      && ![SHELL_CACHE, PAGE_CACHE, ASSET_CACHE].includes(name)).map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") self.skipWaiting();
});

async function trimAssets(cache) {
  const keys = await cache.keys();
  if (keys.length > MAX_ASSETS) {
    await Promise.all(keys.slice(0, keys.length - MAX_ASSETS).map((key) => cache.delete(key)));
  }
}

async function assetResponse(request, event) {
  const cache = await caches.open(ASSET_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok) {
    event.waitUntil((async () => {
      await cache.put(request, response.clone());
      await trimAssets(cache);
    })());
  }
  return response;
}

async function pageResponse(request, event) {
  const url = new URL(request.url);
  const pageKey = `${url.origin}${url.pathname}`;
  const pages = await caches.open(PAGE_CACHE);
  const timeout = new AbortController();
  const timeoutID = setTimeout(() => timeout.abort(), 5000);
  try {
    const response = await fetch(request, { signal: timeout.signal });
    if (response.ok) {
      event.waitUntil(pages.put(pageKey, response.clone()));
      return response;
    }
    const cached = await pages.match(pageKey);
    return cached || response;
  } catch {
    return (await pages.match(pageKey))
      || (await pages.match("/"))
      || (await caches.match("/offline.html"))
      || Response.error();
  } finally {
    clearTimeout(timeoutID);
  }
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET" || request.headers.has("range")) return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(pageResponse(request, event));
    return;
  }

  if (url.pathname.startsWith("/_next/static/")
    || url.pathname.startsWith("/icons/")
    || ["/favicon.ico", "/apple-touch-icon.png", "/manifest.webmanifest"].includes(url.pathname)) {
    event.respondWith(assetResponse(request, event));
  }
});
