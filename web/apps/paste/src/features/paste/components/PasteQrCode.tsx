import CloseRoundedIcon from "@mui/icons-material/CloseRounded";
import { Box, IconButton } from "@mui/material";
import useMediaQuery from "@mui/material/useMediaQuery";
import type {
    PasteResolvedMode,
    PasteThemeTokens,
} from "features/paste/theme/pasteThemeTokens";
import { useEffect, useMemo, useRef, useState } from "react";

interface PasteQrCodeProps {
    value: string;
    tokens: PasteThemeTokens;
    size?: number;
    paperBg?: string;
    borderRadius?: string;
    showCenterLock?: boolean;
    /** When set, shows a floating close control (e.g. to dismiss the QR panel). */
    onClose?: () => void;
    /** Color mode for close button hover; pass when `onClose` is used. */
    resolvedMode?: PasteResolvedMode;
}

interface QRCodeStylingInstance {
    append(container: HTMLElement): void;
    update(options: Record<string, unknown>): void;
    download(
        options?: { name?: string; extension?: string } | string,
    ): Promise<void>;
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
const QR_LOGO_ERROR_CORRECTION_LEVEL: QrErrorCorrectionLevel = "H";
const QUIET_ZONE_MODULES = 4;
const QR_LOAD_ERROR_LABEL = "QR unavailable. Refresh to try again.";

const qrCenterLockDataUrl = (paperBg: string, lockColor: string) => {
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="5" fill="${paperBg}"/><path fill="${lockColor}" d="M10 14v-2.5C10 8.5 12.5 6 16 6s6 2.5 6 5.5V14h1c1.1 0 2 .9 2 2v8c0 1.1-.9 2-2 2H9c-1.1 0-2-.9-2-2v-8c0-1.1.9-2 2-2h1Zm3 0h6v-2.5C19 10.1 17.9 9 16 9s-3 1.1-3 2.5V14Z"/></svg>`;

    return `data:image/svg+xml,${encodeURIComponent(svg)}`;
};

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

const getPasteQrCodeOptions = ({
    value,
    qrSize,
    qrPaperBg,
    tokens,
    showCenterLock,
}: {
    value: string;
    qrSize: number;
    qrPaperBg: string;
    tokens: PasteThemeTokens;
    showCenterLock: boolean;
}) => ({
    width: qrSize,
    height: qrSize,
    type: "svg",
    data: value,
    qrOptions: {
        errorCorrectionLevel: showCenterLock
            ? QR_LOGO_ERROR_CORRECTION_LEVEL
            : QR_ERROR_CORRECTION_LEVEL,
    },
    backgroundOptions: { color: qrPaperBg },
    dotsOptions: { color: tokens.qr.module, type: "rounded" },
    cornersSquareOptions: { color: tokens.qr.finder, type: "extra-rounded" },
    cornersDotOptions: { color: tokens.qr.finder, type: "dot" },
    ...(showCenterLock && {
        image: qrCenterLockDataUrl(qrPaperBg, tokens.qr.finder),
        imageOptions: { hideBackgroundDots: true, imageSize: 0.2, margin: 1 },
    }),
});

export const downloadPasteQrCode = async ({
    value,
    tokens,
    paperBg,
    showCenterLock,
}: {
    value: string;
    tokens: PasteThemeTokens;
    paperBg?: string;
    showCenterLock: boolean;
}) => {
    const qrSize = 512;
    const qrPaperBg = paperBg ?? tokens.qr.paperBg;
    const qrCodeStylingModule = (await import("qr-code-styling")) as unknown;

    if (!isQRCodeStylingModule(qrCodeStylingModule)) {
        throw new Error("Failed to load qr-code-styling");
    }

    const { default: QRCodeStyling } = qrCodeStylingModule;
    const qrOptions = getPasteQrCodeOptions({
        value,
        qrSize,
        qrPaperBg,
        tokens,
        showCenterLock,
    });
    const qrCode = new QRCodeStyling(qrOptions);
    const moduleCount = getQrModuleCount(qrCode);

    if (moduleCount !== undefined) {
        qrCode.update({
            ...qrOptions,
            ...getQrRenderMetrics(qrSize, moduleCount),
        });
    }

    await qrCode.download({ name: "ente-paste-qr", extension: "png" });
};

export const PasteQrCode = ({
    value,
    tokens,
    size,
    paperBg,
    borderRadius,
    showCenterLock = false,
    onClose,
    resolvedMode,
}: PasteQrCodeProps) => {
    const qrContainerRef = useRef<HTMLDivElement | null>(null);
    const qrCodeRef = useRef<QRCodeStylingInstance | null>(null);
    const moduleCountCacheRef = useRef(new Map<string, number>());
    const [qrLoadError, setQrLoadError] = useState(false);
    const isMdUp = useMediaQuery("(min-width:900px)", { noSsr: true });
    const qrSize = size ?? (isMdUp ? 184 : 168);
    const qrPaperBg = paperBg ?? tokens.qr.paperBg;

    const qrOptions = useMemo(
        () =>
            getPasteQrCodeOptions({
                value,
                qrSize,
                qrPaperBg,
                tokens,
                showCenterLock,
            }),
        [
            qrSize,
            showCenterLock,
            tokens.qr.finder,
            tokens.qr.module,
            qrPaperBg,
            value,
        ],
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

    const qrBox = (
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

    if (!onClose) {
        return qrBox;
    }

    const isDark = resolvedMode === "dark";

    return (
        <Box
            sx={{
                position: "relative",
                width: "fit-content",
                maxWidth: "100%",
                mx: "auto",
                overflow: "visible",
            }}
        >
            {qrBox}
            <IconButton
                type="button"
                aria-label="Close QR code"
                disableRipple
                onClick={onClose}
                sx={{
                    position: "absolute",
                    top: 0,
                    right: 0,
                    zIndex: 1,
                    width: 28,
                    height: 28,
                    minWidth: 28,
                    padding: 0,
                    borderRadius: "50%",
                    border: `1px solid ${tokens.button.qrToggleBorder}`,
                    color: tokens.text.secondary,
                    bgcolor: tokens.surface.floatingCardBg,
                    opacity: 1,
                    boxShadow:
                        "0 2px 8px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.05)",
                    transform: "translate(50%, -50%) scale(1)",
                    transformOrigin: "center",
                    transition:
                        "transform 420ms cubic-bezier(0.22, 1, 0.36, 1), background-color 420ms cubic-bezier(0.22, 1, 0.36, 1)",
                    "&:hover": {
                        opacity: 1,
                        transform: "translate(50%, -50%) scale(1.12)",
                        bgcolor: isDark
                            ? "rgba(26, 36, 72, 1)"
                            : "rgba(237, 244, 255, 1)",
                    },
                    "& .MuiSvgIcon-root": { opacity: 1 },
                }}
            >
                <CloseRoundedIcon sx={{ fontSize: 16 }} />
            </IconButton>
        </Box>
    );
};
