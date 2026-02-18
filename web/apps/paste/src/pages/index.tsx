import {
    Box,
    Button,
    Chip,
    CircularProgress,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { EnteLogo, EnteLogoBox } from "ente-base/components/EnteLogo";
import {
    decryptMetadataJSON,
    encryptMetadataJSON,
    fromB64,
    fromB64URLSafeNoPadding,
    generateKey,
    toB64,
    toB64URLSafeNoPadding,
} from "ente-base/crypto";
import Head from "next/head";
import React, { useEffect, useRef, useState } from "react";
import { consumePaste, createPaste, setGuard } from "../services/paste";

const maxChars = 4000;

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

const textFieldSx = {
    "& .MuiOutlinedInput-root.MuiInputBase-multiline": {
        borderRadius: "16px",
        bgcolor: "background.paper2",
        alignItems: "flex-start",
        paddingTop: "10px",
        paddingBottom: "10px",
    },
    "& .MuiInputBase-inputMultiline": {
        paddingTop: "0 !important",
        paddingBottom: "0 !important",
    },
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
        if (mode !== "view" || !accessToken || startedConsumeRef.current) return;
        startedConsumeRef.current = true;

        const run = async () => {
            setConsuming(true);
            setConsumeError(null);

            try {
                const keyFromFragment = window.location.hash.slice(1).trim();
                if (!keyFromFragment) {
                    throw new Error("Missing key in URL");
                }
                const key = await toB64(
                    await fromB64URLSafeNoPadding(keyFromFragment),
                );

                await waitUntilVisible();
                await setGuard(accessToken);
                const payload = await consumePaste(accessToken);
                const decrypted = (await decryptMetadataJSON(payload, key)) as {
                    text?: string;
                };

                if (!decrypted || typeof decrypted.text !== "string") {
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
            const keyURL = await toB64URLSafeNoPadding(await fromB64(key));
            const encrypted = await encryptMetadataJSON({ text: inputText }, key);
            const response = await createPaste({
                encryptedData: encrypted.encryptedData,
                decryptionHeader: encrypted.decryptionHeader,
            });
            const link = `${window.location.origin}/${response.accessToken}#${keyURL}`;
            setCreatedLink(link);
        } catch (error) {
            const message =
                error instanceof Error ? error.message : "Failed to create paste";
            setCreateError(message);
        } finally {
            setCreating(false);
        }
    };

    const copyText = async (value: string) => {
        await navigator.clipboard.writeText(value);
    };

    const shareLink = async (url: string) => {
        if (!navigator.share) {
            await copyText(url);
            return;
        }
        try {
            await navigator.share({ url });
        } catch {
            // no-op on cancel
        }
    };

    return (
        <>
            <Head>
                <meta name="robots" content="noindex, nofollow" />
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
                        width: "100%",
                        bgcolor: "background.default",
                        borderRadius: { xs: "20px", md: "40px" },
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
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
                            mt: { xs: 4, md: 5 },
                            alignSelf: { xs: "center", md: "flex-end" },
                            mr: { xs: 0, md: 6 },
                        }}
                    >
                        <a
                            href="https://ente.io"
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{
                                display: "block",
                                lineHeight: 0,
                                color: "inherit",
                                textDecoration: "none",
                            }}
                        >
                            <EnteLogoBox
                                sx={{
                                    color: "accent.main",
                                    "& svg": { color: "accent.main" },
                                    "& svg path": { fill: "accent.main" },
                                }}
                            >
                                <EnteLogo height={28} />
                            </EnteLogoBox>
                        </a>
                    </Box>

                    <Box
                        sx={{
                            width: "100%",
                            maxWidth: 760,
                            px: { xs: 3, md: 5 },
                            pb: { xs: 5, md: 7 },
                            mt: { xs: 3, md: 4 },
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
                                <Chip variant="outlined" label="24 hour retention max" />
                                <Chip variant="outlined" label="One-time view" />
                                <Chip variant="outlined" label="Purged after open" />
                            </Stack>

                            {mode === "create" && (
                                <>
                                    <TextField
                                        multiline
                                        minRows={10}
                                        placeholder="Paste text (keys, snippets, notes, instructions...)"
                                        value={inputText}
                                        onChange={(e) =>
                                            setInputText(e.target.value)
                                        }
                                        inputProps={{ maxLength: maxChars }}
                                        sx={textFieldSx}
                                    />
                                    <Box
                                        sx={{
                                            display: "flex",
                                            justifyContent: "space-between",
                                            alignItems: "center",
                                        }}
                                    >
                                        <Typography variant="mini" color="text.muted">
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
                                        <Typography color="error">{createError}</Typography>
                                    )}

                                    {createdLink && (
                                        <Stack
                                            spacing={2}
                                            sx={{
                                                p: 2.5,
                                                borderRadius: "20px",
                                                bgcolor: "background.paper2",
                                                border: "1px solid",
                                                borderColor: "stroke.faint",
                                            }}
                                        >
                                            <Typography sx={{ fontWeight: 600 }}>
                                                Your one-time link
                                            </Typography>
                                            <TextField
                                                value={createdLink}
                                                multiline
                                                minRows={2}
                                                InputProps={{ readOnly: true }}
                                                sx={{
                                                    "& .MuiOutlinedInput-root.MuiInputBase-multiline":
                                                        {
                                                            borderRadius: "12px",
                                                            bgcolor:
                                                                "background.default",
                                                            alignItems:
                                                                "flex-start",
                                                            paddingTop: "10px",
                                                            paddingBottom:
                                                                "10px",
                                                        },
                                                    "& .MuiInputBase-inputMultiline":
                                                        {
                                                            paddingTop:
                                                                "0 !important",
                                                            paddingBottom:
                                                                "0 !important",
                                                        },
                                                    "& .MuiOutlinedInput-root": {
                                                        borderRadius: "12px",
                                                        bgcolor: "background.default",
                                                    },
                                                }}
                                            />
                                            <Stack
                                                direction={{ xs: "column", sm: "row" }}
                                                spacing={1}
                                            >
                                                <Button
                                                    variant="outlined"
                                                    onClick={() => copyText(createdLink)}
                                                    sx={{
                                                        textTransform: "none",
                                                        borderRadius: "12px",
                                                    }}
                                                >
                                                    Copy
                                                </Button>
                                                <Button
                                                    variant="outlined"
                                                    onClick={() => shareLink(createdLink)}
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
                                            <Typography>Opening secure paste...</Typography>
                                        </Stack>
                                    )}
                                    {consumeError && (
                                        <Typography color="error">{consumeError}</Typography>
                                    )}
                                    {resolvedText && (
                                        <Stack spacing={2}>
                                            <Typography sx={{ fontWeight: 600 }}>
                                                Paste contents
                                            </Typography>
                                            <TextField
                                                multiline
                                                minRows={10}
                                                value={resolvedText}
                                                InputProps={{ readOnly: true }}
                                                sx={textFieldSx}
                                            />
                                            <Button
                                                variant="outlined"
                                                onClick={() => copyText(resolvedText)}
                                                sx={{
                                                    alignSelf: "flex-start",
                                                    textTransform: "none",
                                                    borderRadius: "12px",
                                                }}
                                            >
                                                Copy text
                                            </Button>
                                            <Typography variant="mini" color="text.muted">
                                                This paste has now been removed from Ente
                                                servers.
                                            </Typography>
                                        </Stack>
                                    )}
                                </>
                            )}
                        </Stack>
                    </Box>
                </Box>
            </Box>
        </>
    );
};

export default Page;
