import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod";

export class ChatKeyNotFoundError extends Error {
    constructor() {
        super("Chat key not found");
        this.name = "ChatKeyNotFoundError";
    }
}

const RemoteChatKey = z.object({
    encryptedKey: z.string().optional(),
    encrypted_key: z.string().optional(),
    header: z.string(),
});

type RemoteChatKey = z.infer<typeof RemoteChatKey>;

export interface ChatKey {
    encryptedKey: string;
    header: string;
}

export const getChatKey = async (): Promise<ChatKey> => {
    const res = await fetch(await apiURL("/llmchat/chat/key"), {
        headers: await authenticatedRequestHeaders(),
    });

    if (res.status == 404) throw new ChatKeyNotFoundError();

    ensureOk(res);
    const data: RemoteChatKey = RemoteChatKey.parse(await res.json());

    const encryptedKey = data.encryptedKey ?? data.encrypted_key;
    if (!encryptedKey) throw new Error("Invalid chat key response");

    return { encryptedKey, header: data.header };
};

export const createChatKey = async (encryptedKey: string, header: string) => {
    const res = await fetch(await apiURL("/llmchat/chat/key"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ encrypted_key: encryptedKey, header }),
    });

    ensureOk(res);
};
