import log from "ente-base/log";

export const resetEnsuAppState = async () => {
    const ignoreError = (label: string, e: unknown) =>
        log.error(`Ignoring error during reset (${label})`, e);

    try {
        const { resetChatStore } = await import("@/services/chat/store");
        await resetChatStore();
    } catch (e) {
        ignoreError("chat store", e);
    }

    window.location.replace("/");
};
