import { UPLOAD_RESULT } from "@/new/photos/services/upload/types";
import { Button, DialogActions } from "@mui/material";
import { t } from "i18next";
import { useContext } from "react";
import UploadProgressContext from "./context";

export function UploadProgressFooter() {
    const { uploadPhase, finishedUploads, retryFailed, onClose } = useContext(
        UploadProgressContext,
    );

    return (
        <DialogActions>
            {uploadPhase == "done" &&
                (finishedUploads?.get(UPLOAD_RESULT.FAILED)?.length > 0 ||
                finishedUploads?.get(UPLOAD_RESULT.BLOCKED)?.length > 0 ? (
                    <Button variant="contained" fullWidth onClick={retryFailed}>
                        {t("RETRY_FAILED")}
                    </Button>
                ) : (
                    <Button variant="contained" fullWidth onClick={onClose}>
                        {t("close")}
                    </Button>
                ))}
        </DialogActions>
    );
}
