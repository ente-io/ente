import { useContext, useEffect, useState } from "react";
import { UploadProgressDialog } from "./dialog";
import { MinimizedUploadProgress } from "./minimized";

import { t } from "i18next";

import { UPLOAD_STAGES } from "constants/upload";
import UploadProgressContext from "contexts/uploadProgress";
import { AppContext } from "pages/_app";
import {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "types/upload/ui";

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
    ...props
}: Props) {
    const appContext = useContext(AppContext);
    const [expanded, setExpanded] = useState(false);

    useEffect(() => {
        if (open) {
            setExpanded(false);
        }
    }, [open]);

    function confirmCancelUpload() {
        appContext.setDialogMessage({
            title: t("STOP_UPLOADS_HEADER"),
            content: t("STOP_ALL_UPLOADS_MESSAGE"),
            proceed: {
                text: t("YES_STOP_UPLOADS"),
                variant: "critical",
                action: props.cancelUploads,
            },
            close: {
                text: t("NO"),
                variant: "secondary",
                action: () => {},
            },
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
