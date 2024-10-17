import type { PublicURL } from "@/media/collection";
import { EnteFile } from "@/media/file";
import { TimeStampListItem } from "components/PhotoList";

export interface PublicCollectionGalleryContextType {
    token: string;
    passwordToken: string;
    referralCode: string | null;
    accessedThroughSharedURL: boolean;
    photoListHeader: TimeStampListItem;
    photoListFooter: TimeStampListItem;
}

export interface LocalSavedPublicCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}

export type SetPublicShareProp = React.Dispatch<
    React.SetStateAction<PublicURL>
>;
