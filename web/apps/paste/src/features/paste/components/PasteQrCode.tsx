import { Box } from "@mui/material";
import useMediaQuery from "@mui/material/useMediaQuery";
import type { PasteThemeTokens } from "features/paste/theme/pasteThemeTokens";
import { useEffect, useMemo, useRef } from "react";

interface PasteQrCodeProps {
    value: string;
    tokens: PasteThemeTokens;
    size?: number;
    paperBg?: string;
    borderRadius?: string;
}

interface QRCodeStylingInstance {
    append(container: HTMLElement): void;
    update(options: Record<string, unknown>): void;
}

type QRCodeStylingConstructor = new (
    options: Record<string, unknown>,
) => QRCodeStylingInstance;

interface QRCodeStylingModule {
    default: QRCodeStylingConstructor;
}

const isQRCodeStylingModule = (
    value: unknown,
): value is QRCodeStylingModule => {
    if (typeof value !== "object" || value === null || !("default" in value)) {
        return false;
    }

    return typeof value.default === "function";
};

export const PasteQrCode = ({
    value,
    tokens,
    size,
    paperBg,
    borderRadius,
}: PasteQrCodeProps) => {
    const qrContainerRef = useRef<HTMLDivElement | null>(null);
    const qrCodeRef = useRef<QRCodeStylingInstance | null>(null);
    const isMdUp = useMediaQuery("(min-width:900px)", { noSsr: true });
    const qrSize = size ?? (isMdUp ? 184 : 168);
    const qrPaperBg = paperBg ?? tokens.qr.paperBg;

    const qrOptions = useMemo(
        () => ({
            width: qrSize,
            height: qrSize,
            type: "svg",
            data: value,
            margin: 8,
            qrOptions: { errorCorrectionLevel: "M" },
            backgroundOptions: { color: qrPaperBg },
            dotsOptions: { color: tokens.qr.module, type: "rounded" },
            cornersSquareOptions: {
                color: tokens.qr.finder,
                type: "extra-rounded",
            },
            cornersDotOptions: { color: tokens.qr.finder, type: "dot" },
        }),
        [qrSize, tokens.qr.finder, tokens.qr.module, qrPaperBg, value],
    );

    useEffect(() => {
        let cancelled = false;

        const renderQr = async () => {
            const container = qrContainerRef.current;
            if (!container) return;

            if (!qrCodeRef.current) {
                const qrCodeStylingModule =
                    (await import("qr-code-styling")) as unknown;
                if (cancelled || !qrContainerRef.current) return;
                if (!isQRCodeStylingModule(qrCodeStylingModule)) return;

                const { default: QRCodeStyling } = qrCodeStylingModule;
                const qrCode = new QRCodeStyling(qrOptions);
                qrCode.append(qrContainerRef.current);
                qrCodeRef.current = qrCode;
                return;
            }

            qrCodeRef.current.update(qrOptions);
        };

        void renderQr();

        return () => {
            cancelled = true;
        };
    }, [qrOptions]);

    useEffect(
        () => () => {
            qrCodeRef.current = null;
            qrContainerRef.current?.replaceChildren();
        },
        [],
    );

    return (
        <Box
            ref={qrContainerRef}
            role="img"
            aria-label="QR code for paste link"
            sx={{
                display: "grid",
                placeItems: "center",
                width: { xs: 144, sm: 168, md: 184 },
                height: { xs: 144, sm: 168, md: 184 },
                ...(size ? { width: qrSize, height: qrSize } : {}),
                borderRadius: borderRadius ?? "10px",
                bgcolor: qrPaperBg,
                overflow: "hidden",
                "& svg, & canvas": {
                    display: "block",
                    width: "100% !important",
                    height: "100% !important",
                },
            }}
        />
    );
};
