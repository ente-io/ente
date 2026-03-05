import { Alert, Box, Button, Stack, TextField, Typography } from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { useSetupI18n } from "ente-base/components/utils/hooks-app";
import log from "ente-base/log";
import React, { useEffect, useMemo, useState } from "react";

interface SetupParams {
    keyBase64Url: string;
    code: string;
    tvHostPort: string;
}

const Page: React.FC = () => {
    const isI18nReady = useSetupI18n();
    const [params, setParams] = useState<SetupParams | undefined>();
    const [isHashParsed, setIsHashParsed] = useState(false);
    const [albumUrl, setAlbumUrl] = useState("");
    const [password, setPassword] = useState("");
    const [error, setError] = useState<string | undefined>();
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        setParams(parseSetupParams(window.location.hash));
        setIsHashParsed(true);
    }, []);

    const postTarget = useMemo(() => {
        if (!params) return undefined;
        return `http://${params.tvHostPort}/set`;
    }, [params]);

    const onSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        if (!params || !postTarget) {
            setError("Pairing data is missing. Please scan the TV QR code again.");
            return;
        }

        const trimmedUrl = albumUrl.trim();
        if (!trimmedUrl) {
            setError("Please enter a public album link.");
            return;
        }

        setError(undefined);
        setIsSubmitting(true);

        try {
            const wasm = await import("ente-wasm");
            wasm.crypto_init();

            const keyBytes = base64UrlToBytes(params.keyBase64Url);
            const keyB64 = bytesToBase64(keyBytes);
            const payload = JSON.stringify({
                code: params.code,
                url: trimmedUrl,
                password: password,
            });
            const payloadB64 = utf8ToBase64(payload);

            const encrypted = wasm.crypto_encrypt_blob(payloadB64, keyB64);
            if (!encrypted.encrypted_data || !encrypted.decryption_header) {
                throw new Error("Encrypted payload is incomplete");
            }

            const hiddenForm = document.createElement("form");
            hiddenForm.method = "POST";
            hiddenForm.action = postTarget;
            hiddenForm.style.display = "none";

            const payloadInput = document.createElement("input");
            payloadInput.name = "payload";
            payloadInput.value = encrypted.encrypted_data;
            hiddenForm.appendChild(payloadInput);

            const headerInput = document.createElement("input");
            headerInput.name = "header";
            headerInput.value = encrypted.decryption_header;
            hiddenForm.appendChild(headerInput);

            document.body.appendChild(hiddenForm);
            hiddenForm.submit();
        } catch (e) {
            log.error("TV setup encryption failed", e);
            setError(
                "Could not prepare secure setup payload. Please scan the TV QR code again and retry.",
            );
            setIsSubmitting(false);
        }
    };

    if (!isI18nReady || !isHashParsed || !params) {
        return (
            <Container>
                <EnteLogo height={45} />
                <Box sx={{ mt: 4 }}>
                    <ActivityIndicator />
                </Box>
                {isI18nReady && isHashParsed && !params && (
                    <Alert severity="error" sx={{ mt: 3, maxWidth: 520 }}>
                        Pairing data is missing or invalid. Please rescan the QR code from your TV setup screen.
                    </Alert>
                )}
            </Container>
        );
    }

    return (
        <Container>
            <EnteLogo height={45} />
            <Typography variant="h3" sx={{ mt: 4, mb: 1 }}>
                Connect Your TV
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 4, textAlign: "center", fontWeight: "regular" }}>
                Paste your Ente public album link below. Data is encrypted on your device before being sent to the TV.
            </Typography>
            <Stack
                component="form"
                onSubmit={onSubmit}
                spacing={2}
                sx={{ width: "100%", maxWidth: 560 }}
            >
                <TextField
                    autoFocus
                    required
                    label="Public album link"
                    placeholder="https://albums.ente.io/...#..."
                    value={albumUrl}
                    onChange={(e) => setAlbumUrl(e.target.value)}
                    fullWidth
                />
                <TextField
                    label="Album password (optional)"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    fullWidth
                />
                {error && <Alert severity="error">{error}</Alert>}
                <Button type="submit" variant="contained" size="large" disabled={isSubmitting}>
                    {isSubmitting ? "Sending secure setup..." : "Send to TV"}
                </Button>
                <Typography color="text.secondary" sx={{ fontSize: "0.75rem" }}>
                    TV target: {postTarget}
                </Typography>
            </Stack>
        </Container>
    );
};

export default Page;

const Container: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Stack
        sx={{
            minHeight: "100svh",
            px: 2,
            py: 6,
            alignItems: "center",
            justifyContent: "center",
            marginInline: "auto",
            maxWidth: 720,
        }}
    >
        {children}
    </Stack>
);

const parseSetupParams = (hash: string): SetupParams | undefined => {
    const fragment = hash.startsWith("#") ? hash.slice(1) : hash;
    if (!fragment) return undefined;

    const params = new URLSearchParams(fragment);
    const keyBase64Url = (params.get("k") || params.get("ek") || "").trim();
    const code = (params.get("c") || params.get("code") || "").trim();
    const tvHostPort = (params.get("tv") || "").trim();

    if (!keyBase64Url || !code || !tvHostPort) return undefined;
    if (!isSafeTvHostPort(tvHostPort)) return undefined;

    return { keyBase64Url, code, tvHostPort };
};

const isSafeTvHostPort = (value: string): boolean => {
    const hostPort = /^(.+):([0-9]{1,5})$/.exec(value);
    if (!hostPort) return false;

    const host = hostPort[1] ?? "";
    const portPart = hostPort[2] ?? "";
    const port = Number.parseInt(portPart, 10);
    if (!host || Number.isNaN(port) || port < 1 || port > 65535) return false;
    if (host.includes("/") || host.includes("?") || host.includes("#")) return false;

    return true;
};

const base64UrlToBytes = (value: string): Uint8Array => {
    const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
    const binary = atob(padded);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    return bytes;
};

const bytesToBase64 = (bytes: Uint8Array): string => {
    const chunkSize = 0x8000;
    let binary = "";
    for (let i = 0; i < bytes.length; i += chunkSize) {
        const chunk = bytes.subarray(i, i + chunkSize);
        for (const value of chunk) {
            binary += String.fromCharCode(value);
        }
    }
    return btoa(binary);
};

const utf8ToBase64 = (value: string): string => {
    return bytesToBase64(new TextEncoder().encode(value));
};
