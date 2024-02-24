import { UPLOAD_STAGES } from "constants/upload";
import { createContext } from "react";
import {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "types/upload/ui";

interface UploadProgressContextType {
    open: boolean;
    onClose: () => void;
    uploadCounter: UploadCounter;
    uploadStage: UPLOAD_STAGES;
    percentComplete: number;
    retryFailed: () => void;
    inProgressUploads: InProgressUpload[];
    uploadFileNames: UploadFileNames;
    finishedUploads: SegregatedFinishedUploads;
    hasLivePhotos: boolean;
    expanded: boolean;
    setExpanded: React.Dispatch<React.SetStateAction<boolean>>;
}
const defaultUploadProgressContext: UploadProgressContextType = {
    open: null,
    onClose: () => null,
    uploadCounter: null,
    uploadStage: null,
    percentComplete: null,
    retryFailed: () => null,
    inProgressUploads: null,
    uploadFileNames: null,
    finishedUploads: null,
    hasLivePhotos: null,
    expanded: null,
    setExpanded: () => null,
};
const UploadProgressContext = createContext<UploadProgressContextType>(
    defaultUploadProgressContext,
);

export default UploadProgressContext;
