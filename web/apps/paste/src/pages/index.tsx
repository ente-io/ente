import {
    Box,
    Button,
    Chip,
    CircularProgress,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import {
    decryptBox,
    decryptMetadataJSON,
    deriveInteractiveKey,
    deriveKey,
    encryptBox,
    encryptMetadataJSON,
    generateKey,
} from "ente-base/crypto";
import { newID } from "ente-base/id";
import Head from "next/head";
import React, { useEffect, useRef, useState } from "react";
import {
    consumePaste,
    createPaste,
    setGuard,
    type PastePayload,
} from "../services/paste";

const maxChars = 4000;
const fragmentSecretLength = 12;
const fragmentSecretPattern = /^[0-9A-Za-z]{12}$/;

type PageMode = "create" | "view";

const waitUntilVisible = () =>
    new Promise<void>((resolve) => {
        if (document.visibilityState === "visible") {
            resolve();
            return;
        }
        const onVisible = () => {
            if (document.visibilityState === "visible") {
                document.removeEventListener("visibilitychange", onVisible);
                resolve();
            }
        };
        document.addEventListener("visibilitychange", onVisible);
    });

const textFieldSx = (
    radius = "16px",
    bgColor = "background.paper2",
    borderColor = "stroke.faint",
) => ({
    margin: 0,
    "& .MuiFilledInput-root": {
        borderRadius: radius,
        bgcolor: bgColor,
        border: "1px solid",
        borderColor,
        alignItems: "flex-start",
        boxSizing: "border-box",
        padding: "10px 12px",
        "&:before": { display: "none" },
        "&:after": { display: "none" },
        "&:hover:not(.Mui-disabled, .Mui-error):before": { display: "none" },
        "&:hover": { bgcolor: bgColor },
        "&.Mui-focused": { bgcolor: bgColor, borderColor: "accent.main" },
    },
    "& .MuiInputBase-input": { padding: "0 !important" },
    "& .MuiInputBase-inputMultiline": {
        padding: "0 !important",
        margin: "0 !important",
    },
    "& .MuiFilledInput-inputMultiline": {
        padding: "0 !important",
        margin: "0 !important",
    },
    "& textarea": { padding: "0 !important", margin: "0 !important" },
});

const createFragmentSecret = () => newID("").slice(0, fragmentSecretLength);

const resolvePasteKey = async (
    fragmentSecret: string,
    payload: PastePayload,
) => {
    if (!fragmentSecretPattern.test(fragmentSecret)) {
        throw new Error("Invalid key in URL");
    }
    const keyEncryptionKey = await deriveKey(
        fragmentSecret,
        payload.kdfNonce,
        payload.kdfOpsLimit,
        payload.kdfMemLimit,
    );
    return await decryptBox(
        {
            encryptedData: payload.encryptedPasteKey,
            nonce: payload.encryptedPasteKeyNonce,
        },
        keyEncryptionKey,
    );
};

const Page: React.FC = () => {
    const [mode, setMode] = useState<PageMode>("create");
    const [accessToken, setAccessToken] = useState<string | null>(null);

    const [inputText, setInputText] = useState("");
    const [creating, setCreating] = useState(false);
    const [createError, setCreateError] = useState<string | null>(null);
    const [createdLink, setCreatedLink] = useState<string | null>(null);

    const [consuming, setConsuming] = useState(false);
    const [consumeError, setConsumeError] = useState<string | null>(null);
    const [resolvedText, setResolvedText] = useState<string | null>(null);

    const startedConsumeRef = useRef(false);
    const createdLinkRef = useRef<HTMLDivElement | null>(null);

    useEffect(() => {
        const cleanPath = window.location.pathname.replace(/^\/+|\/+$/g, "");
        if (!cleanPath) {
            setMode("create");
            return;
        }
        setMode("view");
        setAccessToken(cleanPath.split("/")[0] ?? null);
    }, []);

    useEffect(() => {
        if (mode !== "view" || !accessToken || startedConsumeRef.current)
            return;
        startedConsumeRef.current = true;

        const run = async () => {
            setConsuming(true);
            setConsumeError(null);

            try {
                const fragmentSecret = window.location.hash.slice(1).trim();
                if (!fragmentSecret) {
                    throw new Error("Missing key in URL");
                }

                await waitUntilVisible();
                await setGuard(accessToken);
                const payload = await consumePaste(accessToken);
                const key = await resolvePasteKey(fragmentSecret, payload);
                const decrypted = (await decryptMetadataJSON(
                    {
                        encryptedData: payload.encryptedData,
                        decryptionHeader: payload.decryptionHeader,
                    },
                    key,
                )) as { text?: string };

                if (typeof decrypted.text !== "string") {
                    throw new Error("Unable to decrypt paste");
                }
                setResolvedText(decrypted.text);
            } catch (error) {
                const message =
                    error instanceof Error
                        ? error.message
                        : "Paste is unavailable";
                setConsumeError(message);
            } finally {
                setConsuming(false);
            }
        };

        void run();
    }, [mode, accessToken]);

    useEffect(() => {
        if (!createdLink || mode !== "create") return;
        const linkCard = createdLinkRef.current;
        if (!linkCard) return;

        const rect = linkCard.getBoundingClientRect();
        const viewportHeight =
            window.innerHeight || document.documentElement.clientHeight;
        const isOutOfViewport = rect.top < 0 || rect.bottom > viewportHeight;
        if (!isOutOfViewport) return;

        const reduceMotion = window.matchMedia(
            "(prefers-reduced-motion: reduce)",
        ).matches;
        linkCard.scrollIntoView({
            behavior: reduceMotion ? "auto" : "smooth",
            block: "start",
        });
    }, [createdLink, mode]);

    const handleCreate = async () => {
        setCreateError(null);
        if (!inputText.trim()) {
            setCreateError("Enter some text first");
            return;
        }
        if (inputText.length > maxChars) {
            setCreateError(`Paste is limited to ${maxChars} characters`);
            return;
        }

        setCreating(true);
        try {
            const key = await generateKey();
            const fragmentSecret = createFragmentSecret();
            const encrypted = await encryptMetadataJSON(
                { text: inputText },
                key,
            );
            const keyEncryptionKey = await deriveInteractiveKey(fragmentSecret);
            const encryptedPasteKey = await encryptBox(
                key,
                keyEncryptionKey.key,
            );
            const response = await createPaste({
                encryptedData: encrypted.encryptedData,
                decryptionHeader: encrypted.decryptionHeader,
                encryptedPasteKey: encryptedPasteKey.encryptedData,
                encryptedPasteKeyNonce: encryptedPasteKey.nonce,
                kdfNonce: keyEncryptionKey.salt,
                kdfMemLimit: keyEncryptionKey.memLimit,
                kdfOpsLimit: keyEncryptionKey.opsLimit,
            });
            const link = `${window.location.origin}/${response.accessToken}#${fragmentSecret}`;
            setCreatedLink(link);
        } catch (error) {
            const message =
                error instanceof Error
                    ? error.message
                    : "Failed to create paste";
            setCreateError(message);
        } finally {
            setCreating(false);
        }
    };

    const copyText = async (value: string) => {
        await navigator.clipboard.writeText(value);
    };

    const shareLink = async (url: string) => {
        const share = (
            navigator as Navigator & {
                share?: (data?: ShareData) => Promise<void>;
            }
        ).share;
        if (typeof share !== "function") {
            await copyText(url);
            return;
        }
        try {
            await share.call(navigator, { url });
        } catch {
            // no-op on cancel
        }
    };

    return (
        <>
            <Head>
                <meta name="robots" content="noindex, nofollow" />
                <meta
                    name="description"
                    content="Share sensitive text with one-time, end-to-end encrypted links that auto-expire after 24 hours."
                />
            </Head>
            <Box
                sx={{
                    minHeight: "100dvh",
                    bgcolor: "accent.main",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    p: { xs: 1, md: 3 },
                    boxSizing: "border-box",
                }}
            >
                <Box
                    sx={{
                        minHeight: {
                            xs: "calc(100dvh - 16px)",
                            md: "calc(100dvh - 48px)",
                        },
                        flex: 1,
                        width: "100%",
                        bgcolor: "background.default",
                        borderRadius: { xs: "20px", md: "40px" },
                        display: "grid",
                        gridTemplateRows: "1fr auto",
                        alignItems: "stretch",
                        "& ::selection": {
                            backgroundColor: "accent.main",
                            color: "fixed.white",
                        },
                        "& ::-moz-selection": {
                            backgroundColor: "accent.main",
                            color: "fixed.white",
                        },
                    }}
                >
                    <Box
                        sx={{
                            width: "100%",
                            maxWidth: 760,
                            mx: "auto",
                            px: { xs: 3, md: 5 },
                            pb: { xs: 2, md: 2.5 },
                            mt: { xs: 4, md: 5 },
                        }}
                    >
                        <Stack spacing={2.5}>
                            <Typography
                                variant="h3"
                                sx={{ fontWeight: 700, color: "text.base" }}
                            >
                                Ente Paste
                            </Typography>
                            <Typography color="text.muted">
                                End-to-end encrypted paste sharing for quick,
                                sensitive text. We cannot read your content.
                            </Typography>
                            <Stack
                                direction="row"
                                spacing={1}
                                flexWrap="wrap"
                                useFlexGap
                            >
                                <Chip
                                    variant="outlined"
                                    label="24 hour retention max"
                                />
                                <Chip
                                    variant="outlined"
                                    label="One-time view"
                                />
                                <Chip
                                    variant="outlined"
                                    label="Purged after open"
                                />
                                <Chip
                                    variant="filled"
                                    label="Open source"
                                    component="a"
                                    href="https://github.com/ente-io/ente"
                                    target="_blank"
                                    rel="noopener"
                                    clickable
                                    sx={{
                                        textDecoration: "none",
                                        bgcolor: "accent.main",
                                        color: "fixed.white",
                                        border: "1px solid",
                                        borderColor: "accent.main",
                                        "&:hover": {
                                            bgcolor: "accent.dark",
                                            borderColor: "accent.dark",
                                        },
                                    }}
                                />
                            </Stack>

                            {mode === "create" && (
                                <>
                                    <TextField
                                        variant="filled"
                                        hiddenLabel
                                        slotProps={{
                                            input: { disableUnderline: true },
                                            htmlInput: { maxLength: maxChars },
                                        }}
                                        multiline
                                        minRows={10}
                                        placeholder="Paste text (keys, snippets, notes, instructions...)"
                                        value={inputText}
                                        onChange={(e) =>
                                            setInputText(e.target.value)
                                        }
                                        sx={textFieldSx()}
                                    />
                                    <Box
                                        sx={{
                                            display: "flex",
                                            justifyContent: "space-between",
                                            alignItems: "center",
                                        }}
                                    >
                                        <Typography
                                            variant="mini"
                                            color="text.muted"
                                        >
                                            {inputText.length}/{maxChars}
                                        </Typography>
                                        <Button
                                            variant="contained"
                                            onClick={handleCreate}
                                            disabled={creating}
                                            sx={{
                                                textTransform: "none",
                                                borderRadius: "14px",
                                                bgcolor: "accent.main",
                                                color: "accent.contrastText",
                                                "&:hover": {
                                                    bgcolor: "accent.dark",
                                                },
                                            }}
                                        >
                                            {creating
                                                ? "Creating..."
                                                : "Create secure link"}
                                        </Button>
                                    </Box>

                                    {createError && (
                                        <Typography color="error">
                                            {createError}
                                        </Typography>
                                    )}

                                    {createdLink && (
                                        <Stack
                                            ref={createdLinkRef}
                                            spacing={2}
                                            sx={{
                                                p: 2.5,
                                                borderRadius: "20px",
                                                bgcolor: "background.paper",
                                                border: "1px solid",
                                                borderColor: "stroke.muted",
                                                scrollMarginTop: {
                                                    xs: "16px",
                                                    md: "24px",
                                                },
                                            }}
                                        >
                                            <Typography
                                                sx={{ fontWeight: 600 }}
                                            >
                                                Your one-time link
                                            </Typography>
                                            <TextField
                                                variant="filled"
                                                hiddenLabel
                                                value={createdLink}
                                                multiline
                                                minRows={2}
                                                slotProps={{
                                                    input: {
                                                        readOnly: true,
                                                        disableUnderline: true,
                                                    },
                                                }}
                                                sx={textFieldSx(
                                                    "12px",
                                                    "background.default",
                                                    "stroke.muted",
                                                )}
                                            />
                                            <Stack
                                                direction={{
                                                    xs: "column",
                                                    sm: "row",
                                                }}
                                                spacing={1}
                                            >
                                                <Button
                                                    variant="outlined"
                                                    onClick={() =>
                                                        copyText(createdLink)
                                                    }
                                                    sx={{
                                                        textTransform: "none",
                                                        borderRadius: "12px",
                                                    }}
                                                >
                                                    Copy
                                                </Button>
                                                <Button
                                                    variant="outlined"
                                                    onClick={() =>
                                                        shareLink(createdLink)
                                                    }
                                                    sx={{
                                                        textTransform: "none",
                                                        borderRadius: "12px",
                                                    }}
                                                >
                                                    Share
                                                </Button>
                                            </Stack>
                                        </Stack>
                                    )}
                                </>
                            )}

                            {mode === "view" && (
                                <>
                                    {consuming && (
                                        <Stack
                                            direction="row"
                                            spacing={1.5}
                                            alignItems="center"
                                        >
                                            <CircularProgress
                                                size={18}
                                                sx={{ color: "accent.main" }}
                                            />
                                            <Typography>
                                                Opening secure paste...
                                            </Typography>
                                        </Stack>
                                    )}
                                    {consumeError && (
                                        <Stack
                                            spacing={1.5}
                                            alignItems="flex-start"
                                        >
                                            <Typography color="error">
                                                {consumeError}
                                            </Typography>
                                            <Button
                                                variant="outlined"
                                                component="a"
                                                href="/"
                                                sx={{
                                                    mt: 0.75,
                                                    textTransform: "none",
                                                    borderRadius: "12px",
                                                }}
                                            >
                                                Create new paste
                                            </Button>
                                        </Stack>
                                    )}
                                    {resolvedText && (
                                        <Stack spacing={2}>
                                            <Typography
                                                sx={{ fontWeight: 600 }}
                                            >
                                                Paste contents
                                            </Typography>
                                            <TextField
                                                variant="filled"
                                                hiddenLabel
                                                multiline
                                                minRows={10}
                                                value={resolvedText}
                                                slotProps={{
                                                    input: {
                                                        readOnly: true,
                                                        disableUnderline: true,
                                                    },
                                                }}
                                                sx={textFieldSx()}
                                            />
                                            <Typography
                                                variant="mini"
                                                color="text.muted"
                                            >
                                                This paste has now been removed
                                                from Ente servers.
                                            </Typography>
                                            <Button
                                                variant="outlined"
                                                onClick={() =>
                                                    copyText(resolvedText)
                                                }
                                                sx={{
                                                    alignSelf: "flex-start",
                                                    textTransform: "none",
                                                    borderRadius: "12px",
                                                }}
                                            >
                                                Copy text
                                            </Button>
                                        </Stack>
                                    )}
                                </>
                            )}
                        </Stack>
                    </Box>
                    <Box
                        sx={{
                            width: "100%",
                            maxWidth: 760,
                            mx: "auto",
                            px: { xs: 3, md: 5 },
                            pt: { xs: 2, md: 2.5 },
                            pb: { xs: 3, md: 3.5 },
                        }}
                    >
                        <Stack spacing={1.25} alignItems="center">
                            <a
                                href="https://ente.io"
                                target="_blank"
                                rel="noopener"
                                style={{
                                    display: "block",
                                    lineHeight: 0,
                                    color: "inherit",
                                    textDecoration: "none",
                                }}
                            >
                                <Box
                                    sx={{
                                        color: "accent.main",
                                        "& svg": { color: "accent.main" },
                                        "& svg path": { fill: "accent.main" },
                                    }}
                                >
                                    <EnteLogo height={20} />
                                </Box>
                            </a>
                            <Typography variant="mini" color="text.muted">
                                <a
                                    href="https://ente.io/photos"
                                    target="_blank"
                                    rel="noopener"
                                    style={{
                                        color: "inherit",
                                        textDecoration: "none",
                                    }}
                                >
                                    Photos
                                </a>{" "}
                                {"\u2022"}{" "}
                                <a
                                    href="https://ente.io/locker"
                                    target="_blank"
                                    rel="noopener"
                                    style={{
                                        color: "inherit",
                                        textDecoration: "none",
                                    }}
                                >
                                    Documents
                                </a>{" "}
                                {"\u2022"}{" "}
                                <a
                                    href="https://ente.io/auth"
                                    target="_blank"
                                    rel="noopener"
                                    style={{
                                        color: "inherit",
                                        textDecoration: "none",
                                    }}
                                >
                                    Auth Codes
                                </a>
                            </Typography>
                        </Stack>
                    </Box>
                </Box>
            </Box>
        </>
    );
};

export default Page;
