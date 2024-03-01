import { UPLOAD_RESULT, UPLOAD_STAGES } from "constants/upload";

export type FileID = number;
export type FileName = string;

export type PercentageUploaded = number;
export type UploadFileNames = Map<FileID, FileName>;

export interface UploadCounter {
    finished: number;
    total: number;
}

export interface InProgressUpload {
    localFileID: FileID;
    progress: PercentageUploaded;
}

export interface FinishedUpload {
    localFileID: FileID;
    result: UPLOAD_RESULT;
}

export type InProgressUploads = Map<FileID, PercentageUploaded>;

export type FinishedUploads = Map<FileID, UPLOAD_RESULT>;

export type SegregatedFinishedUploads = Map<UPLOAD_RESULT, FileID[]>;

export interface ProgressUpdater {
    setPercentComplete: React.Dispatch<React.SetStateAction<number>>;
    setUploadCounter: React.Dispatch<React.SetStateAction<UploadCounter>>;
    setUploadStage: React.Dispatch<React.SetStateAction<UPLOAD_STAGES>>;
    setInProgressUploads: React.Dispatch<
        React.SetStateAction<InProgressUpload[]>
    >;
    setFinishedUploads: React.Dispatch<
        React.SetStateAction<SegregatedFinishedUploads>
    >;
    setUploadFilenames: React.Dispatch<React.SetStateAction<UploadFileNames>>;
    setHasLivePhotos: React.Dispatch<React.SetStateAction<boolean>>;
    setUploadProgressView: React.Dispatch<React.SetStateAction<boolean>>;
}
