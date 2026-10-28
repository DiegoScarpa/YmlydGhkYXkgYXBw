"use client";

import { useEffect, useRef, useState } from "react";

/** Registers the offline shell only in production and offers an update without losing local data. */
export default function ServiceWorkerRegister() {
  const [updateReady, setUpdateReady] = useState(false);
  const updateRequested = useRef(false);

  useEffect(() => {
    if (process.env.NODE_ENV !== "production" || !("serviceWorker" in navigator)) return;

    let registration: ServiceWorkerRegistration | undefined;
    let disposed = false;

    const watchInstalling = (worker: ServiceWorker | null) => {
      if (!worker) return;
      const checkState = () => {
        if (!disposed && worker.state === "installed" && navigator.serviceWorker.controller) {
          setUpdateReady(true);
        }
      };
      worker.addEventListener("statechange", checkState);
      checkState();
    };
    const onUpdateFound = () => watchInstalling(registration?.installing ?? null);
    const onControllerChange = () => {
      if (updateRequested.current) window.location.reload();
    };

    navigator.serviceWorker.addEventListener("controllerchange", onControllerChange);
    navigator.serviceWorker.register("/sw.js", { scope: "/" }).then((result) => {
      if (disposed) return;
      registration = result;
      if (registration.waiting && navigator.serviceWorker.controller) setUpdateReady(true);
      registration.addEventListener("updatefound", onUpdateFound);
      watchInstalling(registration.installing);
    }).catch((error: unknown) => {
      console.warn("Remember offline registration failed:", error);
    });

    return () => {
      disposed = true;
      registration?.removeEventListener("updatefound", onUpdateFound);
      navigator.serviceWorker.removeEventListener("controllerchange", onControllerChange);
    };
  }, []);

  const activateUpdate = async () => {
    const registration = await navigator.serviceWorker.getRegistration("/");
    if (!registration?.waiting) return;
    updateRequested.current = true;
    registration.waiting.postMessage({ type: "SKIP_WAITING" });
  };

  if (!updateReady) return null;
  return (
    <div role="status" className="fixed inset-x-4 z-50 mx-auto max-w-md rounded-2xl border border-black/10 bg-white p-4 text-sm text-zinc-900 shadow-xl dark:border-white/10 dark:bg-zinc-800 dark:text-white" style={{ bottom: "calc(6rem + env(safe-area-inset-bottom))" }}>
      <div className="flex items-center gap-3">
        <span className="flex-1">A new version of Remember is ready.</span>
        <button type="button" onClick={() => setUpdateReady(false)} className="min-h-11 px-1 font-semibold text-[#5c54bf] dark:text-[#aaa4f0]">
          Later
        </button>
        <button type="button" onClick={activateUpdate} className="min-h-11 rounded-xl bg-[#5c54bf] px-4 font-semibold text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#5c54bf]">
          Update
        </button>
      </div>
    </div>
  );
}
