import { Box } from "@mui/material";
import useMediaQuery from "@mui/material/useMediaQuery";
import type { PasteThemeTokens } from "features/paste/theme/pasteThemeTokens";
import { useEffect, useMemo, useRef, useState } from "react";

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
    _qr?: { getModuleCount(): number };
}

type QRCodeStylingConstructor = new (
    options: Record<string, unknown>,
) => QRCodeStylingInstance;

interface QRCodeStylingModule {
    default: QRCodeStylingConstructor;
}

type QrErrorCorrectionLevel = "L" | "M" | "Q" | "H";

const QR_ERROR_CORRECTION_LEVEL: QrErrorCorrectionLevel = "M";
const QUIET_ZONE_MODULES = 4;
const QR_LOAD_ERROR_LABEL = "QR unavailable. Refresh to try again.";

const isQRCodeStylingModule = (
    value: unknown,
): value is QRCodeStylingModule => {
    if (typeof value !== "object" || value === null || !("default" in value)) {
        return false;
    }

    return typeof value.default === "function";
};

const getQrModuleCount = (qrCode: QRCodeStylingInstance) => {
    const internalQr = qrCode._qr;

    return internalQr ? internalQr.getModuleCount() : undefined;
};

const getQrRenderMetrics = (qrSize: number, moduleCount: number) => {
    const moduleSize = Math.max(
        1,
        Math.ceil(qrSize / (moduleCount + QUIET_ZONE_MODULES * 2)),
    );

    return {
        renderSize: (moduleCount + QUIET_ZONE_MODULES * 2) * moduleSize,
        margin: QUIET_ZONE_MODULES * moduleSize,
    };
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
    const moduleCountCacheRef = useRef(new Map<string, number>());
    const [qrLoadError, setQrLoadError] = useState(false);
    const isMdUp = useMediaQuery("(min-width:900px)", { noSsr: true });
    const qrSize = size ?? (isMdUp ? 184 : 168);
    const qrPaperBg = paperBg ?? tokens.qr.paperBg;

    const qrOptions = useMemo(
        () => ({
            width: qrSize,
            height: qrSize,
            type: "svg",
            data: value,
            qrOptions: { errorCorrectionLevel: QR_ERROR_CORRECTION_LEVEL },
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
        let isActive = true;

        const renderQr = async () => {
            try {
                const qrCodeStylingModule = (await import(
                    "qr-code-styling"
                )) as unknown;
                if (!isActive) return;

                const container = qrContainerRef.current;
                if (!container) return;
                if (!isQRCodeStylingModule(qrCodeStylingModule)) {
                    throw new Error("Failed to load qr-code-styling");
                }

                const { default: QRCodeStyling } = qrCodeStylingModule;
                const getResolvedQrOptions = (moduleCount: number) => {
                    const { renderSize, margin } = getQrRenderMetrics(
                        qrSize,
                        moduleCount,
                    );

                    return {
                        ...qrOptions,
                        width: renderSize,
                        height: renderSize,
                        margin,
                    };
                };

                const cachedModuleCount =
                    moduleCountCacheRef.current.get(value);

                if (cachedModuleCount !== undefined) {
                    const resolvedQrOptions =
                        getResolvedQrOptions(cachedModuleCount);

                    if (!qrCodeRef.current) {
                        const qrCode = new QRCodeStyling(resolvedQrOptions);
                        qrCode.append(container);
                        qrCodeRef.current = qrCode;
                    } else {
                        qrCodeRef.current.update(resolvedQrOptions);
                    }
                } else if (!qrCodeRef.current) {
                    // Reuse qr-code-styling's internal QR matrix instead of
                    // lazy-loading a second encoder bundle.
                    const qrCode = new QRCodeStyling(qrOptions);
                    const moduleCount = getQrModuleCount(qrCode);

                    if (moduleCount !== undefined) {
                        moduleCountCacheRef.current.set(value, moduleCount);
                        qrCode.update(getResolvedQrOptions(moduleCount));
                    }

                    qrCode.append(container);
                    qrCodeRef.current = qrCode;
                } else {
                    qrCodeRef.current.update(qrOptions);

                    const moduleCount = getQrModuleCount(qrCodeRef.current);
                    if (moduleCount !== undefined) {
                        moduleCountCacheRef.current.set(value, moduleCount);
                        qrCodeRef.current.update(
                            getResolvedQrOptions(moduleCount),
                        );
                    }
                }

                setQrLoadError(false);
            } catch {
                if (!isActive) return;

                setQrLoadError(true);
            }
        };

        void renderQr();

        return () => {
            isActive = false;
        };
    }, [qrOptions, qrSize, value]);

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
            role={qrLoadError ? "status" : "img"}
            aria-label={
                qrLoadError ? QR_LOAD_ERROR_LABEL : "QR code for paste link"
            }
            sx={{
                display: "grid",
                placeItems: "center",
                width: { xs: 144, sm: 168, md: 184 },
                height: { xs: 144, sm: 168, md: 184 },
                ...(size ? { width: qrSize, height: qrSize } : {}),
                borderRadius: borderRadius ?? "10px",
                bgcolor: qrPaperBg,
                overflow: "hidden",
                ...(qrLoadError && {
                    px: 2,
                    "&::after": {
                        content: `"${QR_LOAD_ERROR_LABEL}"`,
                        color: tokens.text.secondary,
                        fontSize: "0.75rem",
                        lineHeight: 1.4,
                        textAlign: "center",
                    },
                }),
                "& svg, & canvas": {
                    display: "block",
                    width: "100% !important",
                    height: "100% !important",
                },
            }}
        />
    );
};
