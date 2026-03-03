import { useEffect, useRef, useState } from "react";
import { consumePaste, setGuard } from "services/paste";
import type { PageMode } from "../types";
import { waitUntilVisible } from "../utils/browser";
import { decryptConsumedPaste } from "../utils/pasteCrypto";

export const useConsumePaste = (mode: PageMode, accessToken: string | null) => {
    const [consuming, setConsuming] = useState(false);
    const [consumeError, setConsumeError] = useState<string | null>(null);
    const [resolvedText, setResolvedText] = useState<string | null>(null);

    const startedConsumeRef = useRef(false);

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
                const decryptedText = await decryptConsumedPaste(
                    fragmentSecret,
                    payload,
                );

                setResolvedText(decryptedText);
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

    return { consuming, consumeError, resolvedText };
};
