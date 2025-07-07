import type { TimeStampListItem } from "components/FileList";
import type { PublicAlbumsCredentials } from "ente-base/http";
import { createContext } from "react";

export interface PublicCollectionGalleryContextType {
    /**
     * The {@link PublicAlbumsCredentials} to use. These are guaranteed to be
     * set if we are in the context of the public albums app, and will be
     * undefined when we're in the default photos app context.
     */
    credentials: PublicAlbumsCredentials | undefined;
    referralCode: string | null;
    photoListHeader: TimeStampListItem;
    photoListFooter: TimeStampListItem;
}

export const PublicCollectionGalleryContext =
    createContext<PublicCollectionGalleryContextType>({
        credentials: undefined,
        referralCode: null,
        photoListHeader: null,
        photoListFooter: null,
    });
