import { EnteFile } from "@/new/photos/types/file";
import { TimeStampListItem } from "components/PhotoList";
import { PublicURL } from "types/collection";

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
