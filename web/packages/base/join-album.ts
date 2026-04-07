export const JOIN_ALBUM_CONTEXT_KEY = "ente_join_album_context";

export interface JoinAlbumContext {
    accessToken: string;
    collectionKey: string; // Base64 encoded collection key for API calls
    collectionKeyHash: string; // Original hash value from URL (base58 or hex)
    collectionID: number;
    accessTokenJWT?: string; // JWT token for password-protected albums
}

/**
 * Retrieve stored album context after authentication.
 * Checks sessionStorage for the stored context.
 */
export const getJoinAlbumContext = (): JoinAlbumContext | null => {
    const stored = sessionStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
    if (!stored) {
        return null;
    }

    try {
        return JSON.parse(stored) as JoinAlbumContext;
    } catch {
        return null;
    }
};

/**
 * Clear the stored album context after successful join or timeout.
 */
export const clearJoinAlbumContext = () => {
    sessionStorage.removeItem(JOIN_ALBUM_CONTEXT_KEY);
};

/**
 * Check if there's a pending album to join.
 */
export const hasPendingAlbumToJoin = (): boolean => {
    return getJoinAlbumContext() !== null;
};
