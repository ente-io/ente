import { TimeStampListItem } from 'components/PhotoList';
import { REPORT_REASON } from 'constants/publicCollection';
import { PublicURL } from 'types/collection';
import { EnteFile } from 'types/file';

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

export interface AbuseReportRequest {
    url: string;
    reason: REPORT_REASON;
    details: AbuseReportDetails;
}

export interface AbuseReportDetails {
    fullName: string;
    email: string;
    comment: string;
    signature: string;
    onBehalfOf: string;
    jobTitle: string;
    address: Address;
}

export interface Address {
    street: string;
    city: string;
    state: string;
    country: string;
    postalCode: string;
    phone: string;
}

export type SetPublicShareProp = React.Dispatch<
    React.SetStateAction<PublicURL>
>;
