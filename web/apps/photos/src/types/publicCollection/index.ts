import type { PublicURL } from "@/media/collection";
import { TimeStampListItem } from "components/PhotoList";

export interface PublicCollectionGalleryContextType {
    token: string;
    passwordToken: string;
    referralCode: string | null;
    accessedThroughSharedURL: boolean;
    photoListHeader: TimeStampListItem;
    photoListFooter: TimeStampListItem;
}

export type SetPublicShareProp = React.Dispatch<
    React.SetStateAction<PublicURL>
>;
