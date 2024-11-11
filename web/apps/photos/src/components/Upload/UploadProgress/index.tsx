import { UPLOAD_STAGES } from "@/new/photos/services/upload/types";
import { useAppContext } from "@/new/photos/types/context";
import { t } from "i18next";
import { useEffect, useState } from "react";
import type {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "services/upload/uploadManager";
import UploadProgressContext from "./context";
import { UploadProgressDialog } from "./dialog";
import { MinimizedUploadProgress } from "./minimized";

interface Props {
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
    cancelUploads: () => void;
}

export default function UploadProgress({
    open,
    uploadCounter,
    uploadStage,
    percentComplete,
    retryFailed,
    uploadFileNames,
    hasLivePhotos,
    inProgressUploads,
    finishedUploads,
    cancelUploads,
    ...props
}: Props) {
    const { showMiniDialog } = useAppContext();
    const [expanded, setExpanded] = useState(false);

    useEffect(() => {
        if (open) {
            setExpanded(false);
        }
    }, [open]);

    function confirmCancelUpload() {
        showMiniDialog({
            title: t("stop_uploads_title"),
            message: t("stop_uploads_message"),
            continue: {
                text: t("yes_stop_uploads"),
                color: "critical",
                action: cancelUploads,
            },
            cancel: t("no"),
        });
    }

    function onClose() {
        if (uploadStage !== UPLOAD_STAGES.FINISH) {
            confirmCancelUpload();
        } else {
            props.onClose();
        }
    }

    if (!open) {
        return <></>;
    }

    return (
        <UploadProgressContext.Provider
            value={{
                open,
                onClose,
                uploadCounter,
                uploadStage,
                percentComplete,
                retryFailed,
                inProgressUploads,
                uploadFileNames,
                finishedUploads,
                hasLivePhotos,
                expanded,
                setExpanded,
            }}
        >
            {expanded ? <UploadProgressDialog /> : <MinimizedUploadProgress />}
        </UploadProgressContext.Provider>
    );
}
