import { SetDialogMessage } from 'components/MessageDialog';
import { REPORT_REASON } from 'constants/publicCollection';
import { EnteFile } from 'types/file';

export interface PublicCollectionGalleryContextType {
    token: string;
    accessedThroughSharedURL: boolean;
    setDialogMessage: SetDialogMessage;
    openReportForm: () => void;
}

export interface LocalSavedPublicCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}

export interface AbuseReportRequest {
    url: string;
    reason: REPORT_REASON;
    comment: string;
}
