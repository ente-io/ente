import {
    Box,
    Button,
    Container,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import {
    MAX_SECRET_BYTES_FOR_PRINTED_CARD,
    canvasToBlob,
    downloadBlob,
    offlineRecoveryFile,
    printBlob,
    renderShareCard,
    sanitizeFilename,
    shareFiles,
} from "features/twoof3/utils/export";
import {
    createQrSvgData,
    decodeQrFromFile,
} from "features/twoof3/utils/qrCode";
import {
    combineShares,
    parseShare,
    splitSecret,
} from "features/twoof3/utils/shamir";
import Head from "next/head";
import type { ChangeEvent, ReactNode } from "react";
import { useDeferredValue, useEffect, useState } from "react";

const APP_LINK = "2of3.ente.io";
const textEncoder = new TextEncoder();

const byteLength = (value: string) => textEncoder.encode(value).length;

const trimToByteLength = (value: string, maxBytes: number) => {
    if (byteLength(value) <= maxBytes) return value;

    const chars = Array.from(value);
    while (chars.length > 0 && byteLength(chars.join("")) > maxBytes) {
        chars.pop();
    }

    return chars.join("");
};

interface ShareCardState {
    encoded: string;
    fingerprint: string;
    index: 1 | 2 | 3;
    qr: NonNullable<ReturnType<typeof createQrSvgData>>;
}

interface SplitSnapshot {
    cards: ShareCardState[];
    error: string | null;
    secret: string;
}

interface RecoverSlot {
    fileName: string;
    value: string;
}

interface RecoverSlotDetails {
    fingerprint: string;
    index: 1 | 2 | 3;
    length: number;
}

const todayLabel = () =>
    new Intl.DateTimeFormat(undefined, {
        day: "numeric",
        month: "long",
        year: "numeric",
    }).format(new Date());

const shareFingerprint = (value: string) =>
    parseShare(value).id.slice(0, 8).toUpperCase();

const EMPTY_SPLIT_SNAPSHOT: SplitSnapshot = {
    cards: [],
    error: null,
    secret: "",
};

const fieldSx = {
    "& .MuiOutlinedInput-root": {
        borderRadius: "18px",
        bgcolor: "var(--paper)",
        "& fieldset": {
            borderWidth: "1.5px",
            borderColor: "var(--line-strong)",
        },
        "&:hover fieldset": { borderWidth: "1.5px", borderColor: "var(--ink)" },
        "&.Mui-focused fieldset": {
            borderWidth: "1.5px",
            borderColor: "var(--ink)",
        },
    },
    "& .MuiInputBase-input": { fontSize: "0.98rem", lineHeight: 1.55 },
    "& .MuiInputLabel-root": { fontWeight: 700, color: "var(--muted)" },
    "& .MuiInputLabel-root.Mui-focused": { color: "var(--ink)" },
};

const Note = ({
    children,
    tone = "plain",
}: {
    children: ReactNode;
    tone?: "plain" | "accent" | "field";
}) => (
    <Box
        sx={{
            border: "1.5px solid",
            borderColor:
                tone === "accent"
                    ? "#111111"
                    : tone === "plain"
                      ? "var(--line-strong)"
                      : "var(--ink)",
            borderRadius: "18px",
            px: 1.5,
            py: 1.15,
            bgcolor:
                tone === "accent"
                    ? "var(--accent)"
                    : tone === "field"
                      ? "var(--field-soft)"
                      : "var(--paper)",
        }}
    >
        <Typography
            sx={{
                color: tone === "accent" ? "#111111" : "var(--ink)",
                fontSize: "0.95rem",
                lineHeight: 1.45,
                fontWeight: tone === "accent" ? 700 : 500,
            }}
        >
            {children}
        </Typography>
    </Box>
);

const QrPreview = ({
    value,
}: {
    value: NonNullable<ReturnType<typeof createQrSvgData>>;
}) => (
    <svg
        viewBox={`0 0 ${value.viewBoxSize} ${value.viewBoxSize}`}
        role="img"
        aria-label="QR code"
        shapeRendering="crispEdges"
        style={{
            width: "100%",
            height: "100%",
            display: "block",
            background: "#ffffff",
            imageRendering: "pixelated",
        }}
    >
        <rect
            width={value.viewBoxSize}
            height={value.viewBoxSize}
            rx="2.5"
            fill="#ffffff"
        />
        {value.modules.map((module) => (
            <rect
                key={`${module.x}-${module.y}`}
                x={module.x}
                y={module.y}
                width="1"
                height="1"
                rx="0.08"
                fill="#111111"
            />
        ))}
    </svg>
);

const ActionButton = ({
    children,
    onClick,
    disabled,
}: {
    children: ReactNode;
    disabled?: boolean;
    onClick: () => void;
}) => (
    <Button
        variant="outlined"
        size="small"
        disabled={disabled}
        onClick={onClick}
        sx={{
            minWidth: 0,
            px: 1.35,
            py: 0.75,
            borderRadius: "999px",
            borderWidth: "1.5px",
            borderColor: "var(--line-strong)",
            color: "var(--ink)",
            bgcolor: "rgba(255,255,255,0.88)",
            "&:hover": {
                borderWidth: "1.5px",
                borderColor: "var(--ink)",
                bgcolor: "var(--paper)",
            },
        }}
    >
        {children}
    </Button>
);

const splitIfPossible = (secret: string): SplitSnapshot => {
    if (!secret.trim()) return EMPTY_SPLIT_SNAPSHOT;

    try {
        const rawShares = splitSecret(secret);
        const cards = rawShares.map((share) => {
            const qr = createQrSvgData(share.encoded);
            if (!qr) {
                throw new Error(
                    "This secret is too long for a clean QR. Keep it shorter.",
                );
            }

            return { ...share, qr };
        });

        return {
            cards: cards.map((card) => ({
                ...card,
                fingerprint: shareFingerprint(card.encoded),
            })),
            error: null,
            secret,
        };
    } catch (error) {
        return {
            cards: [],
            error:
                error instanceof Error
                    ? error.message
                    : "Could not split this secret.",
            secret,
        };
    }
};

const describeRecoverSlot = (value: string): RecoverSlotDetails | null => {
    if (!value.trim()) return null;

    try {
        const parsed = parseShare(value);
        return {
            fingerprint: parsed.id.slice(0, 8).toUpperCase(),
            index: parsed.index,
            length: parsed.length,
        };
    } catch {
        return null;
    }
};

const readShareFile = async (file: File) => {
    if (file.type.startsWith("text/")) {
        return (await file.text()).trim();
    }

    return decodeQrFromFile(file);
};

const copyTextToClipboard = async (value: string) => {
    if ("clipboard" in navigator) {
        await navigator.clipboard.writeText(value);
        return;
    }

    throw new Error("Copy is not supported in this browser.");
};

const Page = () => {
    const [secret, setSecret] = useState("");
    const [title, setTitle] = useState(todayLabel);
    const [busyCard, setBusyCard] = useState<number | null>(null);
    const [downloadAllBusy, setDownloadAllBusy] = useState(false);
    const [actionError, setActionError] = useState<string | null>(null);
    const [copiedCardIndex, setCopiedCardIndex] = useState<number | null>(null);
    const [recoverSlots, setRecoverSlots] = useState<RecoverSlot[]>([
        { fileName: "", value: "" },
        { fileName: "", value: "" },
    ]);
    const [recoverError, setRecoverError] = useState<string | null>(null);
    const [recoveredSecret, setRecoveredSecret] = useState("");
    const [copiedRecoveredSecret, setCopiedRecoveredSecret] = useState(false);
    const [splitSnapshot, setSplitSnapshot] =
        useState<SplitSnapshot>(EMPTY_SPLIT_SNAPSHOT);
    const deferredSecret = useDeferredValue(secret);

    const cards = splitSnapshot.cards;
    const isCardsStale = splitSnapshot.secret !== secret;
    const isReady = !isCardsStale && cards.length === 3;
    const splitError = isCardsStale ? null : splitSnapshot.error;
    const inputStatus = splitError ?? actionError;
    const secretLength = byteLength(secret);
    const cardLabel = title.trim() || todayLabel();
    const recoverSlotDetails = recoverSlots.map((slot) =>
        describeRecoverSlot(slot.value),
    );
    const recoverMismatch =
        recoverSlotDetails[0] &&
        recoverSlotDetails[1] &&
        (recoverSlotDetails[0].fingerprint !==
            recoverSlotDetails[1].fingerprint ||
            recoverSlotDetails[0].length !== recoverSlotDetails[1].length);
    const recoverDuplicateCards =
        !recoverMismatch &&
        recoverSlotDetails[0] &&
        recoverSlotDetails[1] &&
        recoverSlotDetails[0].index === recoverSlotDetails[1].index;
    const hasTwoRecoverValues = recoverSlots.every((slot) => slot.value.trim());
    const canRecover =
        hasTwoRecoverValues && !recoverMismatch && !recoverDuplicateCards;
    const recoverStatus = recoverMismatch
        ? "These two cards are from different sets. Match the # on both cards."
        : recoverDuplicateCards
          ? "Use two different cards from the same set."
          : recoverError;

    useEffect(() => {
        if (!secret.trim()) {
            setSplitSnapshot(EMPTY_SPLIT_SNAPSHOT);
        }
    }, [secret]);

    useEffect(() => {
        if (!deferredSecret.trim()) return;
        setSplitSnapshot(splitIfPossible(deferredSecret));
    }, [deferredSecret]);

    useEffect(() => {
        setRecoveredSecret("");
        setRecoverError(null);
    }, [recoverSlots]);

    useEffect(() => {
        setActionError(null);
        setCopiedCardIndex(null);
    }, [secret]);

    useEffect(() => {
        if (copiedCardIndex === null) return;
        const timer = window.setTimeout(() => {
            setCopiedCardIndex(null);
        }, 1600);
        return () => window.clearTimeout(timer);
    }, [copiedCardIndex]);

    useEffect(() => {
        if (!copiedRecoveredSecret) return;
        const timer = window.setTimeout(() => {
            setCopiedRecoveredSecret(false);
        }, 1600);
        return () => window.clearTimeout(timer);
    }, [copiedRecoveredSecret]);

    const makeCardFile = async (card: ShareCardState) => {
        const canvas = await renderShareCard({
            qrModules: card.qr.modules,
            qrSize: card.qr.viewBoxSize,
            shareIndex: card.index,
            shareText: card.encoded,
            title: cardLabel,
        });
        const blob = await canvasToBlob(canvas);
        const filename = `${sanitizeFilename(cardLabel)}-set-${card.fingerprint.toLowerCase()}-card-${card.index}.png`;
        return new File([blob], filename, { type: "image/png" });
    };

    const runCardAction = async (
        index: number,
        action: (file: File, card: ShareCardState) => Promise<void> | void,
    ) => {
        const card = cards[index];
        if (!card || isCardsStale) return;
        setActionError(null);
        setBusyCard(index);

        try {
            const file = await makeCardFile(card);
            await action(file, card);
        } catch (error) {
            setActionError(
                error instanceof Error ? error.message : "That action failed.",
            );
        } finally {
            setBusyCard(null);
        }
    };

    const onDownloadAll = async () => {
        if (!isReady) return;
        setActionError(null);
        setDownloadAllBusy(true);

        try {
            for (const card of cards) {
                const file = await makeCardFile(card);
                downloadBlob(file, file.name);
            }

            const recovery = await offlineRecoveryFile();
            downloadBlob(recovery, recovery.name);
        } catch (error) {
            setActionError(
                error instanceof Error
                    ? error.message
                    : "Could not download the kit.",
            );
        } finally {
            setDownloadAllBusy(false);
        }
    };

    const onRecover = () => {
        setRecoveredSecret("");
        setRecoverError(null);
        setCopiedRecoveredSecret(false);

        if (!hasTwoRecoverValues) {
            setRecoverError("Upload or paste two cards first.");
            return;
        }

        if (recoverMismatch) {
            setRecoverError(
                "These two cards are from different sets. Match the # on both cards.",
            );
            return;
        }

        if (recoverDuplicateCards) {
            setRecoverError("Use two different cards from the same set.");
            return;
        }

        try {
            const result = combineShares(
                recoverSlots[0]!.value,
                recoverSlots[1]!.value,
            );
            setRecoveredSecret(result);
        } catch (error) {
            setRecoverError(
                error instanceof Error
                    ? error.message
                    : "Could not recover secret.",
            );
        }
    };

    const onCopyCardCode = async (card: ShareCardState) => {
        if (isCardsStale) return;
        setActionError(null);

        try {
            await copyTextToClipboard(card.encoded);
            setCopiedCardIndex(card.index - 1);
        } catch (error) {
            setActionError(
                error instanceof Error
                    ? error.message
                    : "Could not copy that code.",
            );
        }
    };

    const onRecoverFile = async (
        slotIndex: number,
        event: ChangeEvent<HTMLInputElement>,
    ) => {
        const file = event.target.files?.[0];
        if (!file) return;

        try {
            const value = await readShareFile(file);
            parseShare(value);
            setRecoverSlots((previous) =>
                previous.map((slot, index) =>
                    index === slotIndex ? { fileName: file.name, value } : slot,
                ),
            );
            setRecoverError(null);
        } catch (error) {
            setRecoverError(
                error instanceof Error
                    ? error.message
                    : "Could not read that share.",
            );
        } finally {
            event.target.value = "";
        }
    };

    return (
        <>
            <Head>
                <meta
                    name="description"
                    content="Split an Ente recovery key, master password, or another secret into three printable cards. Any two recover it."
                />
                <meta property="og:title" content="2of3" />
                <meta
                    property="og:description"
                    content="A direct, printable 2-of-3 split for important secrets."
                />
            </Head>

            <Box
                sx={(theme) => ({
                    "--app-bg":
                        theme.palette.mode === "dark" ? "#0b0b0b" : "#ffffff",
                    "--shell":
                        theme.palette.mode === "dark" ? "#111111" : "#ffffff",
                    "--paper":
                        theme.palette.mode === "dark" ? "#111111" : "#ffffff",
                    "--field":
                        theme.palette.mode === "dark"
                            ? "rgba(252,239,93,0.16)"
                            : "rgba(252,239,93,0.18)",
                    "--field-soft":
                        theme.palette.mode === "dark"
                            ? "rgba(252,239,93,0.1)"
                            : "rgba(252,239,93,0.12)",
                    "--ink":
                        theme.palette.mode === "dark" ? "#fafafa" : "#111111",
                    "--muted":
                        theme.palette.mode === "dark"
                            ? "rgba(250,250,250,0.68)"
                            : "rgba(17,17,17,0.68)",
                    "--line":
                        theme.palette.mode === "dark"
                            ? "rgba(255,255,255,0.18)"
                            : "rgba(17,17,17,0.18)",
                    "--line-strong":
                        theme.palette.mode === "dark"
                            ? "rgba(255,255,255,0.24)"
                            : "rgba(17,17,17,0.22)",
                    "--accent": theme.palette.primary.main,
                    minHeight: "100vh",
                    bgcolor: "var(--app-bg)",
                    color: "var(--ink)",
                    backgroundImage: "none",
                })}
            >
                <Container maxWidth="xl" sx={{ py: { xs: 2, md: 3 } }}>
                    <Stack spacing={3}>
                        <Stack
                            direction="row"
                            justifyContent="space-between"
                            alignItems="center"
                            sx={{ px: { xs: 0.5, md: 1 } }}
                        >
                            <Typography
                                sx={{
                                    fontWeight: 700,
                                    letterSpacing: "-0.07em",
                                    fontSize: { xs: "1.7rem", md: "2rem" },
                                }}
                            >
                                2of3
                            </Typography>
                            <Box
                                sx={{
                                    fontSize: { xs: "0.85rem", md: "0.95rem" },
                                    color: "var(--muted)",
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 0.4,
                                }}
                            >
                                <Box component="span">by</Box>
                                <Box
                                    component="a"
                                    href="https://ente.io"
                                    target="_blank"
                                    rel="noreferrer"
                                    sx={{
                                        color: "var(--ink)",
                                        fontWeight: 700,
                                        textDecoration: "none",
                                        "&:hover": {
                                            textDecoration: "underline",
                                        },
                                    }}
                                >
                                    Ente
                                </Box>
                            </Box>
                        </Stack>

                        <Box
                            sx={{
                                border: "2px solid",
                                borderColor: "var(--ink)",
                                borderRadius: "32px",
                                overflow: "hidden",
                                bgcolor: "var(--shell)",
                                boxShadow: "0 22px 48px rgba(17,17,17,0.06)",
                                display: "grid",
                                gridTemplateColumns: {
                                    xs: "1fr",
                                    lg: "minmax(320px, 430px) minmax(0, 1fr)",
                                },
                                minHeight: { lg: "calc(100svh - 112px)" },
                            }}
                        >
                            <Stack
                                spacing={2.2}
                                sx={{
                                    p: { xs: 2.25, md: 3 },
                                    bgcolor: "var(--paper)",
                                    borderRight: {
                                        xs: "none",
                                        lg: "2px solid",
                                    },
                                    borderBottom: {
                                        xs: "2px solid",
                                        lg: "none",
                                    },
                                    borderColor: "var(--ink)",
                                }}
                            >
                                <Box
                                    sx={{
                                        width: "fit-content",
                                        px: 1.35,
                                        py: 0.7,
                                        borderRadius: "999px",
                                        border: "1.5px solid",
                                        borderColor: "var(--ink)",
                                        bgcolor: "var(--accent)",
                                    }}
                                >
                                    <Typography
                                        sx={{
                                            fontSize: "0.86rem",
                                            fontWeight: 700,
                                            color: "#111111",
                                        }}
                                    >
                                        Any 2 cards recover it
                                    </Typography>
                                </Box>

                                <Typography
                                    variant="h1"
                                    sx={{
                                        fontSize: {
                                            xs: "2.65rem",
                                            md: "3.45rem",
                                        },
                                        lineHeight: 0.9,
                                        maxWidth: 360,
                                    }}
                                >
                                    Enter a secret.
                                    <br />
                                    Get 3 cards.
                                </Typography>

                                <Typography
                                    sx={{
                                        color: "var(--muted)",
                                        maxWidth: 360,
                                        fontSize: "0.98rem",
                                    }}
                                >
                                    Turn a recovery key, password, or other
                                    secret into 3 cards you can keep in
                                    different places.
                                </Typography>

                                <TextField
                                    label="Secret"
                                    multiline
                                    minRows={7}
                                    maxRows={12}
                                    value={secret}
                                    onChange={(event) =>
                                        setSecret(
                                            trimToByteLength(
                                                event.target.value,
                                                MAX_SECRET_BYTES_FOR_PRINTED_CARD,
                                            ),
                                        )
                                    }
                                    sx={fieldSx}
                                />

                                <Stack spacing={0.8}>
                                    <TextField
                                        label="Card label (optional)"
                                        value={title}
                                        placeholder={todayLabel()}
                                        onChange={(event) =>
                                            setTitle(event.target.value)
                                        }
                                        sx={fieldSx}
                                    />
                                    <Typography
                                        sx={{
                                            color: "var(--muted)",
                                            fontSize: "0.88rem",
                                            textAlign: "right",
                                        }}
                                    >
                                        {secretLength}/
                                        {MAX_SECRET_BYTES_FOR_PRINTED_CARD}
                                    </Typography>
                                </Stack>

                                <Stack spacing={1.1} alignItems="flex-start">
                                    <Button
                                        variant="contained"
                                        size="large"
                                        disabled={!isReady || downloadAllBusy}
                                        onClick={() => {
                                            void onDownloadAll();
                                        }}
                                        sx={{
                                            px: 2.6,
                                            py: 1.25,
                                            borderRadius: "999px",
                                            border: "1.5px solid",
                                            borderColor: "var(--line-strong)",
                                            bgcolor: "var(--accent)",
                                            color: "#111111",
                                            boxShadow: "none",
                                            "&:hover": {
                                                boxShadow: "none",
                                                borderColor: "var(--ink)",
                                                bgcolor: "var(--accent)",
                                            },
                                            "&.Mui-disabled": {
                                                bgcolor: "transparent",
                                                color: "var(--muted)",
                                                borderColor:
                                                    "var(--line-strong)",
                                            },
                                        }}
                                    >
                                        {downloadAllBusy
                                            ? "Preparing downloads..."
                                            : "Download all cards"}
                                    </Button>
                                    <Typography
                                        sx={{
                                            color: "var(--muted)",
                                            fontSize: "0.9rem",
                                        }}
                                    >
                                        Includes an offline recovery page.
                                    </Typography>
                                </Stack>

                                {inputStatus && (
                                    <Note tone="accent">{inputStatus}</Note>
                                )}
                            </Stack>

                            <Stack
                                spacing={2}
                                sx={{ p: { xs: 1.75, md: 2.25 } }}
                            >
                                <Stack
                                    spacing={0.65}
                                    sx={{ px: { xs: 0.3, md: 0.6 } }}
                                >
                                    <Typography
                                        sx={{
                                            fontWeight: 700,
                                            fontSize: "1.05rem",
                                        }}
                                    >
                                        3 recovery cards
                                    </Typography>
                                    <Typography
                                        sx={{
                                            color: "var(--muted)",
                                            fontSize: "0.93rem",
                                        }}
                                    >
                                        Each card is harmless on its own. Print,
                                        save, or share them separately.
                                    </Typography>
                                </Stack>

                                <Box
                                    sx={{
                                        display: "grid",
                                        gridTemplateColumns: {
                                            xs: "1fr",
                                            md: "repeat(2, minmax(0, 1fr))",
                                        },
                                        gap: 1.5,
                                        alignContent: "start",
                                    }}
                                >
                                    {Array.from({ length: 3 }, (_, index) => {
                                        const card = cards[index];
                                        const fingerprint = card
                                            ? `#${card.fingerprint}`
                                            : null;

                                        return (
                                            <Stack
                                                key={index}
                                                sx={{
                                                    border: "1.5px solid",
                                                    borderColor: "var(--ink)",
                                                    borderRadius: "26px",
                                                    bgcolor: "var(--paper)",
                                                    boxShadow:
                                                        "0 14px 28px rgba(17,17,17,0.06)",
                                                    minHeight: 0,
                                                    overflow: "hidden",
                                                }}
                                            >
                                                <Box
                                                    sx={{
                                                        px: 1.35,
                                                        py: 1.05,
                                                        bgcolor:
                                                            "var(--accent)",
                                                        borderBottom:
                                                            "1.5px solid",
                                                        borderColor:
                                                            "var(--ink)",
                                                    }}
                                                >
                                                    <Stack
                                                        direction="row"
                                                        justifyContent="space-between"
                                                        alignItems="center"
                                                        spacing={1}
                                                    >
                                                        <Typography
                                                            sx={{
                                                                fontWeight: 700,
                                                                fontSize:
                                                                    "0.92rem",
                                                                color: "#111111",
                                                            }}
                                                        >
                                                            Card {index + 1}
                                                        </Typography>
                                                        <Typography
                                                            sx={{
                                                                color: "rgba(17,17,17,0.62)",
                                                                fontSize:
                                                                    "0.8rem",
                                                                fontWeight: 500,
                                                            }}
                                                        >
                                                            {APP_LINK}
                                                        </Typography>
                                                    </Stack>
                                                </Box>

                                                <Stack
                                                    spacing={1.2}
                                                    sx={{ p: 1.35 }}
                                                >
                                                    <Typography
                                                        sx={{
                                                            fontWeight: 700,
                                                            fontSize: "1rem",
                                                            lineHeight: 1.2,
                                                        }}
                                                    >
                                                        {cardLabel}
                                                    </Typography>

                                                    <Box
                                                        sx={{
                                                            aspectRatio:
                                                                "1 / 1",
                                                            border: "1.5px solid",
                                                            borderColor:
                                                                "var(--line-strong)",
                                                            bgcolor: "#ffffff",
                                                            borderRadius:
                                                                "22px",
                                                            overflow: "hidden",
                                                            p: 1.35,
                                                            display: "grid",
                                                            placeItems:
                                                                "center",
                                                        }}
                                                    >
                                                        {card ? (
                                                            <QrPreview
                                                                value={card.qr}
                                                            />
                                                        ) : (
                                                            <Typography
                                                                sx={{
                                                                    textAlign:
                                                                        "center",
                                                                    color: "#111111",
                                                                    opacity: 0.6,
                                                                    px: 3,
                                                                    fontSize:
                                                                        "0.95rem",
                                                                }}
                                                            >
                                                                Enter a secret
                                                                to generate card{" "}
                                                                {index + 1}.
                                                            </Typography>
                                                        )}
                                                    </Box>

                                                    {card && (
                                                        <Stack
                                                            direction="row"
                                                            justifyContent="space-between"
                                                            alignItems="center"
                                                            spacing={1}
                                                            sx={{ mt: 0.15 }}
                                                        >
                                                            <Button
                                                                variant="text"
                                                                size="small"
                                                                disabled={
                                                                    isCardsStale
                                                                }
                                                                onClick={() => {
                                                                    void onCopyCardCode(
                                                                        card,
                                                                    );
                                                                }}
                                                                sx={{
                                                                    minWidth: 0,
                                                                    px: 0,
                                                                    py: 0,
                                                                    color: "var(--muted)",
                                                                    fontSize:
                                                                        "0.8rem",
                                                                    fontWeight: 700,
                                                                    textTransform:
                                                                        "none",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "transparent",
                                                                        color: "var(--ink)",
                                                                    },
                                                                }}
                                                            >
                                                                {copiedCardIndex ===
                                                                index
                                                                    ? "Copied"
                                                                    : "Copy code"}
                                                            </Button>
                                                            <Typography
                                                                sx={{
                                                                    color: "var(--muted)",
                                                                    fontSize:
                                                                        "0.78rem",
                                                                    fontWeight: 500,
                                                                    textAlign:
                                                                        "right",
                                                                }}
                                                            >
                                                                {fingerprint}
                                                            </Typography>
                                                        </Stack>
                                                    )}

                                                    <Stack
                                                        direction="row"
                                                        spacing={0.8}
                                                        useFlexGap
                                                        flexWrap="wrap"
                                                    >
                                                        <ActionButton
                                                            disabled={
                                                                !card ||
                                                                isCardsStale ||
                                                                busyCard ===
                                                                    index
                                                            }
                                                            onClick={() => {
                                                                void runCardAction(
                                                                    index,
                                                                    (file) => {
                                                                        printBlob(
                                                                            file,
                                                                            file.name,
                                                                        );
                                                                    },
                                                                );
                                                            }}
                                                        >
                                                            Print
                                                        </ActionButton>
                                                        <ActionButton
                                                            disabled={
                                                                !card ||
                                                                isCardsStale ||
                                                                busyCard ===
                                                                    index
                                                            }
                                                            onClick={() => {
                                                                void runCardAction(
                                                                    index,
                                                                    (file) => {
                                                                        downloadBlob(
                                                                            file,
                                                                            file.name,
                                                                        );
                                                                    },
                                                                );
                                                            }}
                                                        >
                                                            Download
                                                        </ActionButton>
                                                        <ActionButton
                                                            disabled={
                                                                !card ||
                                                                isCardsStale ||
                                                                busyCard ===
                                                                    index
                                                            }
                                                            onClick={() => {
                                                                void runCardAction(
                                                                    index,
                                                                    async (
                                                                        file,
                                                                    ) => {
                                                                        try {
                                                                            await shareFiles(
                                                                                [
                                                                                    file,
                                                                                ],
                                                                            );
                                                                        } catch {
                                                                            downloadBlob(
                                                                                file,
                                                                                file.name,
                                                                            );
                                                                        }
                                                                    },
                                                                );
                                                            }}
                                                        >
                                                            Share
                                                        </ActionButton>
                                                    </Stack>
                                                </Stack>
                                            </Stack>
                                        );
                                    })}
                                </Box>
                            </Stack>
                        </Box>

                        <Box
                            sx={{
                                border: "2px solid",
                                borderColor: "var(--ink)",
                                borderRadius: "28px",
                                overflow: "hidden",
                                bgcolor: "var(--shell)",
                                boxShadow: "0 16px 34px rgba(17,17,17,0.04)",
                            }}
                        >
                            <Stack
                                spacing={2.25}
                                sx={{ p: { xs: 2.1, md: 2.6 } }}
                            >
                                <Box
                                    sx={{
                                        width: "fit-content",
                                        px: 1.1,
                                        py: 0.45,
                                        borderRadius: "999px",
                                        bgcolor: "var(--paper)",
                                        border: "1.5px solid",
                                        borderColor: "var(--line-strong)",
                                    }}
                                >
                                    <Typography
                                        sx={{
                                            fontWeight: 700,
                                            fontSize: "0.82rem",
                                        }}
                                    >
                                        Recover later
                                    </Typography>
                                </Box>

                                <Box>
                                    <Typography
                                        variant="h2"
                                        sx={{
                                            fontSize: {
                                                xs: "2rem",
                                                md: "2.55rem",
                                            },
                                            lineHeight: 0.92,
                                        }}
                                    >
                                        Use any 2 cards to recover
                                    </Typography>
                                    <Typography
                                        sx={{
                                            color: "var(--muted)",
                                            mt: 1,
                                            maxWidth: 680,
                                        }}
                                    >
                                        Upload two card images, or paste two
                                        codes if you copied them earlier.
                                    </Typography>
                                </Box>

                                <Box
                                    sx={{
                                        display: "grid",
                                        gridTemplateColumns: {
                                            xs: "1fr",
                                            md: "repeat(2, minmax(0, 1fr))",
                                        },
                                        gap: 1.5,
                                    }}
                                >
                                    {recoverSlots.map((slot, index) => {
                                        const slotDetails =
                                            recoverSlotDetails[index];

                                        return (
                                            <Stack
                                                key={index}
                                                spacing={1.15}
                                                sx={{
                                                    p: 1.45,
                                                    border: "1.5px solid",
                                                    borderColor:
                                                        "var(--line-strong)",
                                                    borderRadius: "24px",
                                                    bgcolor: "var(--paper)",
                                                }}
                                            >
                                                <Stack
                                                    direction="row"
                                                    justifyContent="space-between"
                                                    alignItems="center"
                                                    spacing={1}
                                                >
                                                    <Box
                                                        sx={{
                                                            width: "fit-content",
                                                            px: 1,
                                                            py: 0.42,
                                                            borderRadius:
                                                                "999px",
                                                            border: "1.5px solid",
                                                            borderColor:
                                                                "var(--line-strong)",
                                                        }}
                                                    >
                                                        <Typography
                                                            sx={{
                                                                fontWeight: 700,
                                                                fontSize:
                                                                    "0.84rem",
                                                            }}
                                                        >
                                                            Card {index + 1}
                                                        </Typography>
                                                    </Box>
                                                    <Button
                                                        variant="outlined"
                                                        component="label"
                                                        size="small"
                                                        sx={{
                                                            alignSelf:
                                                                "flex-start",
                                                            borderWidth:
                                                                "1.5px",
                                                            borderColor:
                                                                "var(--line-strong)",
                                                            color: "var(--ink)",
                                                            bgcolor:
                                                                "var(--paper)",
                                                            "&:hover": {
                                                                borderWidth:
                                                                    "1.5px",
                                                                borderColor:
                                                                    "var(--ink)",
                                                            },
                                                        }}
                                                    >
                                                        {slot.fileName
                                                            ? "Replace image"
                                                            : "Upload image"}
                                                        <input
                                                            hidden
                                                            type="file"
                                                            accept="image/*,text/plain"
                                                            onChange={(
                                                                event,
                                                            ) => {
                                                                void onRecoverFile(
                                                                    index,
                                                                    event,
                                                                );
                                                            }}
                                                        />
                                                    </Button>
                                                </Stack>

                                                <Typography
                                                    sx={{
                                                        color:
                                                            slot.fileName ||
                                                            slotDetails
                                                                ? "var(--ink)"
                                                                : "var(--muted)",
                                                        fontSize: "0.88rem",
                                                    }}
                                                >
                                                    {slotDetails
                                                        ? `${slot.fileName ? `${slot.fileName} · ` : ""}Card ${slotDetails.index} from #${slotDetails.fingerprint}`
                                                        : slot.fileName
                                                          ? slot.fileName
                                                          : "Upload a saved card image, or paste a copied code."}
                                                </Typography>
                                                <TextField
                                                    label={`Code ${index + 1}`}
                                                    multiline
                                                    minRows={6}
                                                    value={slot.value}
                                                    onChange={(event) =>
                                                        setRecoverSlots(
                                                            (previous) =>
                                                                previous.map(
                                                                    (
                                                                        current,
                                                                        currentIndex,
                                                                    ) =>
                                                                        currentIndex ===
                                                                        index
                                                                            ? {
                                                                                  ...current,
                                                                                  fileName:
                                                                                      "",
                                                                                  value: event
                                                                                      .target
                                                                                      .value,
                                                                              }
                                                                            : current,
                                                                ),
                                                        )
                                                    }
                                                    placeholder={`Paste code ${index + 1}`}
                                                    sx={fieldSx}
                                                />
                                            </Stack>
                                        );
                                    })}
                                </Box>

                                {recoverStatus && (
                                    <Note tone="accent">{recoverStatus}</Note>
                                )}

                                <Stack
                                    direction={{ xs: "column", sm: "row" }}
                                    spacing={1.25}
                                    alignItems={{
                                        xs: "stretch",
                                        sm: "flex-start",
                                    }}
                                >
                                    <Button
                                        variant="outlined"
                                        size="large"
                                        onClick={onRecover}
                                        disabled={!canRecover}
                                        sx={{
                                            alignSelf: "flex-start",
                                            px: 2.3,
                                            py: 1.15,
                                            borderRadius: "999px",
                                            borderWidth: "1.5px",
                                            borderColor: "var(--ink)",
                                            color: "#111111",
                                            bgcolor: "var(--accent)",
                                            "&:hover": {
                                                borderWidth: "1.5px",
                                                borderColor: "var(--ink)",
                                                bgcolor: "var(--accent)",
                                            },
                                            "&.Mui-disabled": {
                                                bgcolor: "transparent",
                                                color: "var(--muted)",
                                                borderColor:
                                                    "var(--line-strong)",
                                            },
                                        }}
                                    >
                                        Recover secret
                                    </Button>
                                </Stack>

                                {recoveredSecret && (
                                    <Stack
                                        spacing={1.2}
                                        sx={{
                                            p: 1.45,
                                            border: "1.5px solid",
                                            borderColor: "var(--ink)",
                                            borderRadius: "24px",
                                            bgcolor: "var(--field-soft)",
                                        }}
                                    >
                                        <Stack
                                            direction={{
                                                xs: "column",
                                                sm: "row",
                                            }}
                                            justifyContent="space-between"
                                            alignItems={{
                                                xs: "flex-start",
                                                sm: "center",
                                            }}
                                            spacing={1}
                                        >
                                            <Typography
                                                sx={{
                                                    fontWeight: 700,
                                                    fontSize: "1rem",
                                                }}
                                            >
                                                Recovered secret
                                            </Typography>
                                            <Button
                                                variant="outlined"
                                                size="small"
                                                onClick={() => {
                                                    void copyTextToClipboard(
                                                        recoveredSecret,
                                                    )
                                                        .then(() => {
                                                            setCopiedRecoveredSecret(
                                                                true,
                                                            );
                                                        })
                                                        .catch(
                                                            (
                                                                error: unknown,
                                                            ) => {
                                                                setRecoverError(
                                                                    error instanceof
                                                                        Error
                                                                        ? error.message
                                                                        : "Could not copy the recovered secret.",
                                                                );
                                                            },
                                                        );
                                                }}
                                                sx={{
                                                    borderWidth: "1.5px",
                                                    borderColor: "var(--ink)",
                                                    color: "#111111",
                                                    bgcolor: "var(--accent)",
                                                    "&:hover": {
                                                        borderWidth: "1.5px",
                                                        borderColor:
                                                            "var(--ink)",
                                                        bgcolor:
                                                            "var(--accent)",
                                                    },
                                                }}
                                            >
                                                {copiedRecoveredSecret
                                                    ? "Copied"
                                                    : "Copy"}
                                            </Button>
                                        </Stack>

                                        <TextField
                                            multiline
                                            minRows={4}
                                            value={recoveredSecret}
                                            slotProps={{
                                                input: { readOnly: true },
                                            }}
                                            sx={fieldSx}
                                        />
                                    </Stack>
                                )}
                            </Stack>
                        </Box>
                    </Stack>
                </Container>
            </Box>
        </>
    );
};

export default Page;
