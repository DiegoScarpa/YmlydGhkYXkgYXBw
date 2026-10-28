/** Store a small JPEG in IndexedDB, matching the native app's 512 px photo limit. */
export async function compressPhoto(file: Blob): Promise<Blob> {
  if (typeof document === "undefined") throw new Error("Photo processing requires a browser");
  let source: CanvasImageSource;
  let width: number;
  let height: number;
  let bitmap: ImageBitmap | null = null;
  let objectURL: string | null = null;

  try {
    if (typeof createImageBitmap === "function") {
      try {
        bitmap = await createImageBitmap(file);
      } catch {
        // Safari may decode a selected image through <img> even when ImageBitmap cannot.
      }
    }
    if (bitmap) {
      source = bitmap;
      width = bitmap.width;
      height = bitmap.height;
    } else {
      objectURL = URL.createObjectURL(file);
      const image = new Image();
      image.src = objectURL;
      await image.decode();
      source = image;
      width = image.naturalWidth;
      height = image.naturalHeight;
    }
    if (!width || !height) throw new Error("This image could not be opened");
    const scale = Math.min(1, 512 / Math.max(width, height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round(width * scale));
    canvas.height = Math.max(1, Math.round(height * scale));
    const context = canvas.getContext("2d");
    if (!context) throw new Error("Photo processing is unavailable");
    context.drawImage(source, 0, 0, canvas.width, canvas.height);
    return await new Promise<Blob>((resolve, reject) => {
      canvas.toBlob((blob) => blob ? resolve(blob) : reject(new Error("Photo processing failed")), "image/jpeg", 0.82);
    });
  } finally {
    bitmap?.close();
    if (objectURL) URL.revokeObjectURL(objectURL);
  }
}
