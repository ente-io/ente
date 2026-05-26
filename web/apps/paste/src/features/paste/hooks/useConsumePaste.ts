import { useCallback, useEffect, useRef, useState } from "react";
import { consumePaste, setGuard } from "services/paste";
import type { PageMode } from "../types";
import { waitUntilVisible } from "../utils/browser";
import {
    decryptConsumedPaste,
    parsePasteKey,
    type PasteKey,
} from "../utils/pasteCrypto";

export const useConsumePaste = (mode: PageMode, accessToken: string | null) => {
    const [consuming, setConsuming] = useState(false);
    const [consumeError, setConsumeError] = useState<string | null>(null);
    const [resolvedText, setResolvedText] = useState<string | null>(null);
    const [passwordRequired, setPasswordRequired] = useState(false);

    const startedConsumeRef = useRef(false);
    const pasteKeyRef = useRef<PasteKey | null>(null);

    const consume = useCallback(
        async (pasteKey: PasteKey, password?: string) => {
            if (!accessToken || startedConsumeRef.current) {
                return;
            }
            startedConsumeRef.current = true;
            try {
                setConsuming(true);
                setConsumeError(null);

                await waitUntilVisible();
                await setGuard(accessToken);
                const payload = await consumePaste(accessToken);
                let decryptedText: string;
                try {
                    decryptedText = await decryptConsumedPaste(
                        pasteKey,
                        payload,
                        password,
                    );
                } catch (error) {
                    if (pasteKey.passwordRequired) {
                        throw new Error("Incorrect paste password");
                    }
                    throw error;
                }

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
        },
        [accessToken],
    );

    useEffect(() => {
        if (mode !== "view" || !accessToken || pasteKeyRef.current) return;

        try {
            const fragment = window.location.hash.slice(1).trim();
            if (!fragment) {
                throw new Error("Missing key in URL");
            }

            const pasteKey = parsePasteKey(fragment);
            pasteKeyRef.current = pasteKey;
            if (pasteKey.passwordRequired) {
                setPasswordRequired(true);
            } else {
                void consume(pasteKey);
            }
        } catch (error) {
            const message =
                error instanceof Error ? error.message : "Paste is unavailable";
            setConsumeError(message);
        }
    }, [mode, accessToken, consume]);

    const submitPassword = async (password: string) => {
        if (!password) {
            setConsumeError("Enter the paste password");
            return;
        }
        if (!pasteKeyRef.current) {
            setConsumeError("Missing key in URL");
            return;
        }
        await consume(pasteKeyRef.current, password);
    };

    return {
        consuming,
        consumeError,
        resolvedText,
        passwordRequired,
        submitPassword,
    };
};
