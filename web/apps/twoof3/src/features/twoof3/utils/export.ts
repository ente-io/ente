import { maxSecretBytesForEncodedShareLength, parseShare } from "./shamir";

interface ShareCardAsset {
    qrModules: { finder: boolean; x: number; y: number }[];
    qrSize: number;
    shareIndex: number;
    shareText: string;
    title: string;
}

const CARD_WIDTH = 1400;
const CARD_HEIGHT = 1840;
const CARD_RADIUS = 64;
const QR_SIZE = 860;
const APP_LINK = "2of3.ente.io";
const PRINTED_SHARE_CHARS_PER_LINE = 80;
const PRINTED_SHARE_LINE_COUNT = 4;
export const MAX_PRINTED_SHARE_LENGTH =
    PRINTED_SHARE_CHARS_PER_LINE * PRINTED_SHARE_LINE_COUNT;
export const MAX_SECRET_BYTES_FOR_PRINTED_CARD =
    maxSecretBytesForEncodedShareLength(MAX_PRINTED_SHARE_LENGTH);

const wrapCanvasText = (
    context: CanvasRenderingContext2D,
    text: string,
    maxWidth: number,
    maxLines: number,
) => {
    const words = text.trim().split(/\s+/u).filter(Boolean);
    if (words.length === 0) return [""];

    const lines: string[] = [];
    let current = "";

    for (const word of words) {
        const candidate = current ? `${current} ${word}` : word;
        if (context.measureText(candidate).width <= maxWidth) {
            current = candidate;
            continue;
        }

        if (current) lines.push(current);
        current = word;

        if (lines.length === maxLines - 1) break;
    }

    if (current && lines.length < maxLines) {
        lines.push(current);
    }

    const consumedWords = lines.join(" ").split(/\s+/u).filter(Boolean).length;
    if (consumedWords < words.length && lines.length > 0) {
        const lastLine = lines[lines.length - 1]!;
        lines[lines.length - 1] = `${lastLine.replace(/[. ]+$/u, "")}…`;
    }

    return lines;
};

const balanceCanvasText = (
    value: string,
    maxLineLength: number,
    maxLines: number,
) => {
    const lineCount = Math.min(
        maxLines,
        Math.ceil(value.length / maxLineLength),
    );
    if (lineCount <= 1) return [value];

    const chunks: string[] = [];
    const baseLength = Math.floor(value.length / lineCount);
    let remainder = value.length % lineCount;
    let offset = 0;

    for (let index = 0; index < lineCount; index++) {
        const chunkLength = baseLength + (remainder > 0 ? 1 : 0);
        chunks.push(value.slice(offset, offset + chunkLength));
        offset += chunkLength;
        if (remainder > 0) remainder -= 1;
    }

    return chunks;
};

const fitCodeFont = (
    context: CanvasRenderingContext2D,
    lines: string[],
    maxWidth: number,
    maxHeight: number,
) => {
    for (let fontSize = 24; fontSize >= 18; fontSize -= 1) {
        context.font = `500 ${fontSize}px Menlo, Monaco, "Courier New", monospace`;
        const widestLine = Math.max(
            ...lines.map((line) => context.measureText(line).width),
        );
        const lineHeight = fontSize + 4;
        if (widestLine <= maxWidth && lineHeight * lines.length <= maxHeight) {
            return { fontSize, lineHeight };
        }
    }

    return { fontSize: 18, lineHeight: 22 };
};

const drawQr = (
    context: CanvasRenderingContext2D,
    modules: ShareCardAsset["qrModules"],
    qrSize: number,
    left: number,
    top: number,
    size: number,
) => {
    const moduleSize = size / qrSize;

    context.fillStyle = "#ffffff";
    context.fillRect(left, top, size, size);

    for (const module of modules) {
        context.fillStyle = "#111111";
        context.fillRect(
            left + module.x * moduleSize,
            top + module.y * moduleSize,
            moduleSize,
            moduleSize,
        );
    }
};

const ensureShareCardFonts = async () => {
    if (typeof document === "undefined" || !("fonts" in document)) return;

    await Promise.allSettled([
        document.fonts.load('700 54px "Space Grotesk"'),
        document.fonts.load('700 36px "Space Grotesk"'),
        document.fonts.load('500 32px "Space Grotesk"'),
        document.fonts.load('700 22px "Space Grotesk"'),
        document.fonts.load('500 22px "Space Grotesk"'),
    ]);
};

export const renderShareCard = async ({
    qrModules,
    qrSize,
    shareIndex,
    shareText,
    title,
}: ShareCardAsset) => {
    await ensureShareCardFonts();

    const fingerprint = parseShare(shareText).id.slice(0, 8).toUpperCase();
    const shareLines = balanceCanvasText(
        shareText,
        PRINTED_SHARE_CHARS_PER_LINE,
        PRINTED_SHARE_LINE_COUNT,
    );
    const canvas = document.createElement("canvas");
    canvas.width = CARD_WIDTH;
    canvas.height = CARD_HEIGHT;

    const context = canvas.getContext("2d");
    if (!context) throw new Error("Could not render canvas.");

    context.fillStyle = "#ffffff";
    context.fillRect(0, 0, CARD_WIDTH, CARD_HEIGHT);

    context.fillStyle = "#ffffff";
    context.beginPath();
    context.roundRect(48, 48, CARD_WIDTH - 96, CARD_HEIGHT - 96, CARD_RADIUS);
    context.fill();
    context.lineWidth = 3;
    context.strokeStyle = "#111111";
    context.stroke();

    context.fillStyle = "rgb(252, 239, 93)";
    context.beginPath();
    context.roundRect(84, 84, CARD_WIDTH - 168, 132, 32);
    context.fill();

    context.fillStyle = "#111111";
    context.font = '700 36px "Space Grotesk", sans-serif';
    context.fillText(`Card ${shareIndex}`, 124, 166);

    context.fillStyle = "rgba(17,17,17,0.62)";
    context.font = '500 32px "Space Grotesk", sans-serif';
    const appLinkWidth = context.measureText(APP_LINK).width;
    context.fillText(APP_LINK, CARD_WIDTH - 124 - appLinkWidth, 166);

    context.fillStyle = "#111111";
    context.font = '700 54px "Space Grotesk", sans-serif';
    const titleLines = wrapCanvasText(context, title, 940, 2);
    titleLines.forEach((line, index) => {
        context.fillText(line, 120, 304 + index * 66);
    });

    context.fillStyle = "#ffffff";
    context.beginPath();
    context.roundRect(120, 392, 1160, 1088, 48);
    context.fill();
    context.lineWidth = 2.5;
    context.strokeStyle = "rgba(17,17,17,0.22)";
    context.stroke();

    drawQr(context, qrModules, qrSize, 270, 506, QR_SIZE);

    context.fillStyle = "rgba(17,17,17,0.68)";
    context.font = '700 22px "Space Grotesk", sans-serif';
    context.fillText("Code", 120, 1536);

    context.fillStyle = "rgba(17,17,17,0.45)";
    context.font = '500 22px "Space Grotesk", sans-serif';
    const fingerprintLabel = `#${fingerprint}`;
    const fingerprintWidth = context.measureText(fingerprintLabel).width;
    context.fillText(
        fingerprintLabel,
        CARD_WIDTH - 120 - fingerprintWidth,
        1536,
    );

    context.fillStyle = "rgba(17,17,17,0.04)";
    context.beginPath();
    context.roundRect(120, 1560, 1160, 148, 28);
    context.fill();
    context.lineWidth = 2;
    context.strokeStyle = "rgba(17,17,17,0.18)";
    context.stroke();

    const codeLeft = 148;
    const codeTop = 1603;
    const codeMaxWidth = 1104;
    const codeMaxHeight = 104;
    const codeFont = fitCodeFont(
        context,
        shareLines,
        codeMaxWidth,
        codeMaxHeight,
    );
    context.fillStyle = "#111111";
    context.font = `500 ${codeFont.fontSize}px Menlo, Monaco, "Courier New", monospace`;
    shareLines.forEach((line, index) => {
        context.fillText(line, codeLeft, codeTop + index * codeFont.lineHeight);
    });

    return canvas;
};

export const canvasToBlob = async (canvas: HTMLCanvasElement) =>
    new Promise<Blob>((resolve, reject) => {
        canvas.toBlob((blob) => {
            if (!blob) {
                reject(new Error("Could not encode PNG."));
                return;
            }
            resolve(blob);
        }, "image/png");
    });

export const createOfflineRecoveryHtml = () => `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>2of3 recovery</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #ffffff;
      --paper: #ffffff;
      --field: rgba(252, 239, 93, 0.12);
      --ink: #111111;
      --muted: rgba(17,17,17,0.72);
      --yellow: rgb(252, 239, 93);
      --line: rgba(17, 17, 17, 0.18);
      --line-strong: rgba(17, 17, 17, 0.22);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Space Grotesk", "Helvetica Neue", sans-serif;
      background: var(--bg);
      color: var(--ink);
    }
    main {
      width: min(960px, calc(100vw - 32px));
      margin: 0 auto;
      padding: 32px 0 56px;
    }
    .panel {
      background: var(--paper);
      border: 2px solid var(--ink);
      border-radius: 24px;
      padding: 24px;
    }
    h1 {
      font-family: "Space Grotesk", sans-serif;
      font-size: clamp(2.1rem, 5vw, 3.4rem);
      line-height: 0.92;
      letter-spacing: -0.06em;
      margin: 0 0 12px;
    }
    p { color: var(--muted); line-height: 1.6; }
    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 16px;
      padding: 10px 14px;
      border-radius: 999px;
      background: var(--yellow);
      border: 2px solid var(--ink);
      font-weight: 700;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin-top: 24px;
    }
    textarea, input[type="file"] {
      width: 100%;
      border-radius: 18px;
      border: 2px solid var(--ink);
      background: white;
      padding: 14px 16px;
      font: inherit;
    }
    textarea {
      min-height: 180px;
      resize: vertical;
    }
    button {
      margin-top: 18px;
      border: 0;
      border-radius: 999px;
      padding: 14px 20px;
      background: var(--yellow);
      color: var(--ink);
      font: inherit;
      font-weight: 700;
      cursor: pointer;
    }
    .result {
      margin-top: 18px;
      white-space: pre-wrap;
      background: var(--paper);
      border: 2px solid var(--ink);
      padding: 16px;
      border-radius: 18px;
    }
    .error {
      color: var(--ink);
      background: var(--yellow);
      border: 2px solid var(--ink);
      border-radius: 18px;
      padding: 12px 14px;
      margin-top: 12px;
    }
  </style>
</head>
<body>
  <main>
    <div class="panel">
      <div class="eyebrow">Recover later</div>
      <h1>Recover with any two cards.</h1>
      <p>This file works offline. Upload two card images if your browser can read QR codes, or paste the two code strings manually.</p>
      <div class="grid">
        <div>
          <input id="file-a" type="file" accept="image/*,text/plain" />
          <textarea id="input-a" placeholder="Paste share 1"></textarea>
        </div>
        <div>
          <input id="file-b" type="file" accept="image/*,text/plain" />
          <textarea id="input-b" placeholder="Paste share 2"></textarea>
        </div>
      </div>
      <button id="recover">Recover secret</button>
      <div id="error" class="error"></div>
      <div id="result" class="result" hidden></div>
    </div>
  </main>
  <script>
    const GF_POLY = 0x11b;
    const VERSION = 1;
    const HEADER_LENGTH = 14;
    const gfMul = (left, right) => {
      let result = 0;
      let a = left;
      let b = right;
      while (b > 0) {
        if (b & 1) result ^= a;
        a <<= 1;
        if (a & 0x100) a ^= GF_POLY;
        b >>= 1;
      }
      return result;
    };
    const gfPow = (value, exponent) => {
      let result = 1;
      for (let count = 0; count < exponent; count++) {
        result = gfMul(result, value);
      }
      return result;
    };
    const gfInv = (value) => {
      if (value === 0) throw new Error("Division by zero");
      return gfPow(value, 254);
    };
    const gfDiv = (left, right) => {
      if (left === 0) return 0;
      return gfMul(left, gfInv(right));
    };
    const checksumBytes = (bytes) => {
      let hash = 0x811c9dc5;
      for (const byte of bytes) {
        hash ^= byte;
        hash = Math.imul(hash, 0x01000193) >>> 0;
      }
      return new Uint8Array([(hash >>> 24) & 255, (hash >>> 16) & 255, (hash >>> 8) & 255, hash & 255]);
    };
    const base64UrlEncode = (bytes) => {
      let binary = "";
      for (const byte of bytes) binary += String.fromCharCode(byte);
      return btoa(binary).replace(/\\+/g, "-").replace(/\\//g, "_").replace(/=+$/u, "");
    };
    const base64UrlDecode = (value) => {
      const padded = value.replace(/-/g, "+").replace(/_/g, "/");
      const normalized = padded + "=".repeat((4 - (padded.length % 4 || 4)) % 4);
      const binary = atob(normalized);
      return Uint8Array.from(binary, (char) => char.charCodeAt(0));
    };
    const parseShare = (input) => {
      const encoded = input.trim();
      if (!encoded.startsWith("2of3-")) throw new Error("That code does not look like a 2of3 share.");
      const payload = base64UrlDecode(encoded.slice(5));
      if (payload.length <= HEADER_LENGTH) throw new Error("That share looks incomplete.");
      const version = payload[0];
      const index = payload[1];
      const length = ((payload[2] || 0) << 8) | (payload[3] || 0);
      if (version !== VERSION) throw new Error("This share was created by a newer format.");
      if (![1,2,3].includes(index)) throw new Error("This share number is invalid.");
      if (payload.length !== HEADER_LENGTH + length) throw new Error("This share was cut off.");
      return {
        checksum: payload.slice(10, 14),
        data: payload.slice(14),
        id: base64UrlEncode(payload.slice(4, 10)),
        index,
        length,
      };
    };
    const combineShares = (firstInput, secondInput) => {
      const first = parseShare(firstInput);
      const second = parseShare(secondInput);
      if (first.id !== second.id || first.length !== second.length) throw new Error("These two cards are from different sets. Match the # on both cards.");
      if (first.index === second.index) throw new Error("Use two different cards from the same set.");
      const output = new Uint8Array(first.length);
      const denominator = first.index ^ second.index;
      for (let index = 0; index < first.length; index++) {
        const left = gfMul(first.data[index], gfDiv(second.index, denominator));
        const right = gfMul(second.data[index], gfDiv(first.index, denominator));
        output[index] = left ^ right;
      }
      const expectedChecksum = checksumBytes(output);
      for (let i = 0; i < expectedChecksum.length; i++) {
        if (expectedChecksum[i] !== first.checksum[i] || expectedChecksum[i] !== second.checksum[i]) {
          throw new Error("These shares did not reconstruct a valid secret.");
        }
      }
      return new TextDecoder().decode(output);
    };
    const fileToText = async (file) => {
      if (file.type.startsWith("text/")) return file.text();
      if (!("BarcodeDetector" in window)) throw new Error("QR image upload is not supported in this browser. Paste the code instead.");
      const detector = new BarcodeDetector({ formats: ["qr_code"] });
      const bitmap = await createImageBitmap(file);
      const results = await detector.detect(bitmap);
      bitmap.close();
      const value = results[0] && results[0].rawValue;
      if (!value) throw new Error("Could not read a QR code from that image.");
      return value;
    };
    const bindFile = (fileId, textareaId) => {
      const fileInput = document.getElementById(fileId);
      const textarea = document.getElementById(textareaId);
      fileInput.addEventListener("change", async (event) => {
        const file = event.target.files && event.target.files[0];
        if (!file) return;
        try {
          textarea.value = (await fileToText(file)).trim();
        } catch (error) {
          document.getElementById("error").textContent = error.message || String(error);
        }
      });
    };
    bindFile("file-a", "input-a");
    bindFile("file-b", "input-b");
    document.getElementById("recover").addEventListener("click", () => {
      const errorNode = document.getElementById("error");
      const resultNode = document.getElementById("result");
      errorNode.textContent = "";
      resultNode.hidden = true;
      try {
        const secret = combineShares(
          document.getElementById("input-a").value,
          document.getElementById("input-b").value
        );
        resultNode.textContent = secret;
        resultNode.hidden = false;
      } catch (error) {
        errorNode.textContent = error.message || String(error);
      }
    });
  </script>
</body>
</html>`;

export const offlineRecoveryFile = () =>
    new File([createOfflineRecoveryHtml()], "2of3-recovery.html", {
        type: "text/html;charset=utf-8",
    });

export const shareFiles = async (files: File[]) => {
    const api = navigator as Navigator & {
        canShare?: (data?: ShareData) => boolean;
        share?: (data?: ShareData) => Promise<void>;
    };

    if (
        typeof api.share !== "function" ||
        typeof api.canShare !== "function" ||
        !api.canShare({ files })
    ) {
        throw new Error("Sharing files is not supported here.");
    }

    await api.share({
        files,
        title: "2of3 cards",
        text: "Keep these cards separate. Any 2 can recover the secret.",
    });
};

export const printBlob = (blob: Blob, title: string) => {
    const url = URL.createObjectURL(blob);
    const popup = window.open("", "_blank", "noopener,noreferrer");
    if (!popup) {
        URL.revokeObjectURL(url);
        throw new Error("Allow pop-ups to print this card.");
    }

    const { document } = popup;
    document.title = title;

    const style = document.createElement("style");
    style.textContent =
        "body{margin:0;background:#fff;display:grid;place-items:center;min-height:100vh}img{max-width:100vw;max-height:100vh}@media print{body{margin:0}}";
    document.head.appendChild(style);

    const image = document.createElement("img");
    image.src = url;
    image.alt = title;
    image.addEventListener("load", () => {
        popup.print();
        popup.setTimeout(() => popup.close(), 100);
    });
    document.body.appendChild(image);
    popup.addEventListener("beforeunload", () => {
        URL.revokeObjectURL(url);
    });
};

export const downloadBlob = (blob: Blob, filename: string) => {
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
};

export const sanitizeFilename = (value: string) =>
    value
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "")
        .slice(0, 48) || "2of3";
