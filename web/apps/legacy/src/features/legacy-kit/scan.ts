import type { PDFDocumentProxy, PDFPageProxy } from "pdfjs-dist";

type DecodeQR = (typeof import("qr/decode.js"))["default"];

const legacyKitShareMetadataPrefix = "ente-legacy-kit-share-v1:";
const legacyKitBundleMetadataPrefix = "ente-legacy-kit-shares-v1:";
const pdfFallbackTimeoutMS = 15_000;

interface DecodableImage {
    data: Uint8ClampedArray | number[];
    height: number;
    width: number;
}

interface DrawableImage {
    dispose: () => void;
    height: number;
    source: CanvasImageSource;
    width: number;
}

let decodeQrPromise: Promise<DecodeQR> | undefined;

const loadDecodeQr = () =>
    (decodeQrPromise ??= import("qr/decode.js")
        .then(({ default: decodeQR }) => decodeQR)
        .catch((error: unknown) => {
            decodeQrPromise = undefined;
            throw error;
        }));

const isPDF = (file: File) =>
    file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf");

const isPlainText = (file: File) =>
    file.type.startsWith("text/") || file.name.toLowerCase().endsWith(".txt");

const withTimeout = async <T>(
    promise: Promise<T>,
    timeoutMS: number,
    message: string,
) => {
    let timeout: ReturnType<typeof setTimeout> | undefined;
    try {
        return await Promise.race([
            promise,
            new Promise<never>((_, reject) => {
                timeout = setTimeout(
                    () => reject(new Error(message)),
                    timeoutMS,
                );
            }),
        ]);
    } finally {
        if (timeout) clearTimeout(timeout);
    }
};

const findJsonObject = (value: string) => {
    const start = value.indexOf('{"pv"');
    if (start < 0) return undefined;

    let depth = 0;
    let inString = false;
    let escaped = false;

    for (let index = start; index < value.length; index++) {
        const char = value[index];
        if (escaped) {
            escaped = false;
            continue;
        }
        if (char === "\\") {
            escaped = true;
            continue;
        }
        if (char === '"') {
            inString = !inString;
            continue;
        }
        if (inString) {
            continue;
        }
        if (char === "{") {
            depth += 1;
        } else if (char === "}") {
            depth -= 1;
            if (depth === 0) {
                return value.slice(start, index + 1);
            }
        }
    }

    return undefined;
};

const markerPayload = (value: string, marker: string) => {
    const markerStart = value.indexOf(marker);
    if (markerStart < 0) return undefined;

    const payloadStart = markerStart + marker.length;
    const payload = /^[A-Za-z0-9_-]+/.exec(value.slice(payloadStart))?.[0];
    return payload || undefined;
};

const decodeBase64URLUTF8 = (value: string) => {
    const base64 = value
        .replaceAll("-", "+")
        .replaceAll("_", "/")
        .padEnd(Math.ceil(value.length / 4) * 4, "=");
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index++) {
        bytes[index] = binary.charCodeAt(index);
    }
    return new TextDecoder().decode(bytes);
};

const codeFromPDFMetadata = (bytes: Uint8Array) => {
    const pdfText = new TextDecoder("latin1").decode(bytes);
    const sharePayload = markerPayload(pdfText, legacyKitShareMetadataPrefix);
    if (sharePayload) {
        return decodeBase64URLUTF8(sharePayload);
    }

    const bundlePayload = markerPayload(pdfText, legacyKitBundleMetadataPrefix);
    if (!bundlePayload) return undefined;

    const payloads: unknown = JSON.parse(decodeBase64URLUTF8(bundlePayload));
    if (!Array.isArray(payloads)) {
        throw new Error("Legacy Kit PDF metadata is invalid.");
    }
    if (payloads.length === 1 && typeof payloads[0] === "string") {
        return payloads[0];
    }
    throw new Error("Choose individual Legacy Kit sheet PDFs.");
};

const loadImageFromFile = (file: File) =>
    new Promise<DrawableImage>((resolve, reject) => {
        const objectURL = URL.createObjectURL(file);
        const image = new Image();
        image.onload = () => {
            resolve({
                dispose: () => URL.revokeObjectURL(objectURL),
                height: image.naturalHeight,
                source: image,
                width: image.naturalWidth,
            });
        };
        image.onerror = () => {
            URL.revokeObjectURL(objectURL);
            reject(new Error("Could not read that image."));
        };
        image.src = objectURL;
    });

const loadDrawableFromFile = async (file: File): Promise<DrawableImage> => {
    if (typeof createImageBitmap === "function") {
        try {
            const bitmap = await createImageBitmap(file);
            return {
                dispose: () => bitmap.close(),
                height: bitmap.height,
                source: bitmap,
                width: bitmap.width,
            };
        } catch {
            // Fall through to HTMLImageElement decoding.
        }
    }

    return loadImageFromFile(file);
};

const imageDataFromDrawable = (drawable: DrawableImage) => {
    const canvas = document.createElement("canvas");
    canvas.width = drawable.width;
    canvas.height = drawable.height;
    const context = canvas.getContext("2d", { willReadFrequently: true });
    if (!context) {
        throw new Error("Could not read that image.");
    }
    context.drawImage(drawable.source, 0, 0, canvas.width, canvas.height);
    return context.getImageData(0, 0, canvas.width, canvas.height);
};

const imageDataFromFile = async (file: File) => {
    const drawable = await loadDrawableFromFile(file);
    try {
        return imageDataFromDrawable(drawable);
    } finally {
        drawable.dispose();
    }
};

const cropImage = (
    image: DecodableImage,
    leftRatio: number,
    topRatio: number,
    widthRatio: number,
    heightRatio: number,
): DecodableImage | undefined => {
    const left = Math.max(0, Math.floor(image.width * leftRatio));
    const top = Math.max(0, Math.floor(image.height * topRatio));
    const width = Math.min(
        image.width - left,
        Math.floor(image.width * widthRatio),
    );
    const height = Math.min(
        image.height - top,
        Math.floor(image.height * heightRatio),
    );
    if (width < 64 || height < 64) return undefined;

    const data = new Uint8ClampedArray(width * height * 4);
    for (let row = 0; row < height; row++) {
        const sourceOffset = ((top + row) * image.width + left) * 4;
        const targetOffset = row * width * 4;
        data.set(
            image.data.slice(sourceOffset, sourceOffset + width * 4),
            targetOffset,
        );
    }
    return { data, height, width };
};

const decodeQrImage = async (image: DecodableImage) => {
    const decodeQR = await loadDecodeQr();
    const crops = [
        [0.05, 0.4, 0.48, 0.42],
        [0.07, 0.44, 0.36, 0.3],
        [0.1, 0.46, 0.3, 0.25],
        [0.08, 0.2, 0.84, 0.64],
    ] as const;
    const attempts: {
        image: DecodableImage;
        options?: { cropToSquare?: boolean };
    }[] = [{ image, options: { cropToSquare: false } }, { image }];

    for (const crop of crops) {
        const [leftRatio, topRatio, widthRatio, heightRatio] = crop;
        const cropped = cropImage(
            image,
            leftRatio,
            topRatio,
            widthRatio,
            heightRatio,
        );
        if (!cropped) continue;
        attempts.push(
            { image: cropped, options: { cropToSquare: false } },
            { image: cropped },
        );
    }

    let lastError: unknown;
    for (const attempt of attempts) {
        try {
            return decodeQR(attempt.image, attempt.options).trim();
        } catch (error) {
            lastError = error;
        }
    }

    throw lastError instanceof Error
        ? lastError
        : new Error("Could not read that QR code.");
};

const textFromPDF = async (pdf: PDFDocumentProxy) => {
    const chunks: string[] = [];
    for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber++) {
        const page = await pdf.getPage(pageNumber);
        const textContent = await page.getTextContent();
        chunks.push(
            textContent.items
                .map((item) => ("str" in item ? item.str : ""))
                .join(""),
        );
    }
    return chunks.join("\n");
};

const renderPDFPage = async (page: PDFPageProxy) => {
    const baseViewport = page.getViewport({ scale: 1 });
    const scale = Math.min(
        3,
        Math.max(2, 1800 / Math.max(baseViewport.width, baseViewport.height)),
    );
    const viewport = page.getViewport({ scale });
    const canvas = document.createElement("canvas");
    canvas.width = Math.ceil(viewport.width);
    canvas.height = Math.ceil(viewport.height);
    const context = canvas.getContext("2d", { willReadFrequently: true });
    if (!context) {
        throw new Error("Could not render that PDF.");
    }
    await page.render({ canvas, canvasContext: context, viewport }).promise;
    return context.getImageData(0, 0, canvas.width, canvas.height);
};

const decodeQrFromPDFBytes = async (bytes: Uint8Array) => {
    const pdfjs = (await import(
        "pdfjs-dist/legacy/webpack.mjs"
    )) as unknown as typeof import("pdfjs-dist");
    const loadingTask = pdfjs.getDocument({ data: bytes.slice() });
    let pdf: PDFDocumentProxy;
    try {
        pdf = await withTimeout(
            loadingTask.promise,
            pdfFallbackTimeoutMS,
            "Could not read that PDF. Download the sheet again and try the new PDF.",
        );
    } catch (error) {
        await loadingTask.destroy().catch(() => undefined);
        throw error;
    }

    try {
        const textCode = findJsonObject(await textFromPDF(pdf));
        if (textCode) {
            return textCode;
        }

        for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber++) {
            const page = await pdf.getPage(pageNumber);
            try {
                return await decodeQrImage(await renderPDFPage(page));
            } catch {
                // Try the next page before surfacing a failure.
            }
        }
    } finally {
        await pdf.destroy();
    }

    throw new Error("Could not find a Legacy Kit QR code in that PDF.");
};

const decodeQrFromPDF = async (file: File) => {
    const bytes = new Uint8Array(await file.arrayBuffer());
    const metadataCode = codeFromPDFMetadata(bytes);
    if (metadataCode) return metadataCode;
    return decodeQrFromPDFBytes(bytes);
};

export const readLegacyKitCodeFromFile = async (file: File) => {
    if (isPDF(file)) return decodeQrFromPDF(file);
    if (isPlainText(file)) {
        const value = await file.text();
        return findJsonObject(value) ?? value.trim();
    }
    return decodeQrImage(await imageDataFromFile(file));
};
