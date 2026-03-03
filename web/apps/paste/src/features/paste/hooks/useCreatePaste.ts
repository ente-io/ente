import { useState } from "react";
import { createPaste } from "services/paste";
import { MAX_PASTE_CHARS } from "../constants";
import { encryptPasteForCreate } from "../utils/pasteCrypto";

const buildPasteLink = (accessToken: string, fragmentSecret: string) =>
    `${window.location.origin}/${accessToken}#${fragmentSecret}`;

export const useCreatePaste = () => {
    const [inputText, setInputText] = useState("");
    const [creating, setCreating] = useState(false);
    const [createError, setCreateError] = useState<string | null>(null);
    const [createdLink, setCreatedLink] = useState<string | null>(null);

    const createSecureLink = async () => {
        setCreateError(null);

        if (!inputText.trim()) {
            setCreateError("Enter some text first");
            return;
        }

        if (inputText.length > MAX_PASTE_CHARS) {
            setCreateError(`Paste is limited to ${MAX_PASTE_CHARS} characters`);
            return;
        }

        setCreating(true);
        try {
            const { fragmentSecret, payload } =
                await encryptPasteForCreate(inputText);
            const response = await createPaste(payload);
            setCreatedLink(
                buildPasteLink(response.accessToken, fragmentSecret),
            );
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

    return {
        inputText,
        setInputText,
        creating,
        createError,
        createdLink,
        createSecureLink,
    };
};
