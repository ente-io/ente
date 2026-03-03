import { qrcodegen } from "./qrcodegen";

interface QrModule {
    finder: boolean;
    x: number;
    y: number;
}

interface QrSvgData {
    modules: QrModule[];
    viewBoxSize: number;
}

const QR_BORDER_MODULES = 2;

const isFinderModule = (x: number, y: number, size: number) => {
    const inTopBand = y < 7;
    const inBottomBand = y >= size - 7;
    const inLeftBand = x < 7;
    const inRightBand = x >= size - 7;

    return (
        (inTopBand && inLeftBand) ||
        (inTopBand && inRightBand) ||
        (inBottomBand && inLeftBand)
    );
};

export const createQrSvgData = (value: string): QrSvgData | null => {
    try {
        const qr = qrcodegen.QrCode.encodeText(
            value,
            qrcodegen.QrCode.Ecc.MEDIUM,
        );
        const modules: QrModule[] = [];

        for (let y = 0; y < qr.size; y++) {
            for (let x = 0; x < qr.size; x++) {
                if (!qr.getModule(x, y)) continue;
                modules.push({
                    finder: isFinderModule(x, y, qr.size),
                    x: x + QR_BORDER_MODULES,
                    y: y + QR_BORDER_MODULES,
                });
            }
        }

        return { modules, viewBoxSize: qr.size + QR_BORDER_MODULES * 2 };
    } catch {
        return null;
    }
};
