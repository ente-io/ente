import { TimeStampListItem } from "components/PhotoList";
import { PublicURL } from "types/collection";
import { EnteFile } from "types/file";

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
