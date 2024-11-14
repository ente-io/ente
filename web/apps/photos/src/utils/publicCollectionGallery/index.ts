import { TimeStampListItem } from "components/PhotoList";
import { createContext } from "react";

export interface PublicCollectionGalleryContextType {
    token: string;
    passwordToken: string;
    referralCode: string | null;
    accessedThroughSharedURL: boolean;
    photoListHeader: TimeStampListItem;
    photoListFooter: TimeStampListItem;
}

export const PublicCollectionGalleryContext =
    createContext<PublicCollectionGalleryContextType>({
        token: null,
        passwordToken: null,
        referralCode: null,
        accessedThroughSharedURL: false,
        photoListHeader: null,
        photoListFooter: null,
    });
