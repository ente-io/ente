import type { PublicAlbumsCredentials } from "ente-base/http";
import type { Collection } from "ente-media/collection";
import type { RefObject } from "react";
import { joinPublicAlbumViaRedirect } from "@/public-album/services/join-public-album-redirect";

export interface UseJoinAlbumProps {
    /** Collection to join */
    publicCollection?: Collection;
    /** Access token for the public link */
    accessToken?: string;
    /** Collection key from URL (base64 encoded) */
    collectionKey?: string;
    /** Credentials ref for JWT token access */
    credentials?: RefObject<PublicAlbumsCredentials | undefined>;
}

export interface UseJoinAlbumReturn {
    /** Handler for join album action */
    handleJoinAlbum: () => void;
}

/**
 * Custom hook that provides join album logic and handlers.
 * Components can use this hook and apply their own button styling.
 */
export const useJoinAlbum = ({
    publicCollection,
    accessToken,
    collectionKey,
    credentials,
}: UseJoinAlbumProps): UseJoinAlbumReturn => {
    const handleJoinAlbum = () =>
        joinPublicAlbumViaRedirect({
            publicCollection,
            accessToken,
            collectionKey,
            credentials,
        });

    return { handleJoinAlbum };
};
