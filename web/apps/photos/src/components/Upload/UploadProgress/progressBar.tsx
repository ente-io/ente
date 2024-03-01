import { Box, Divider, LinearProgress } from "@mui/material";
import { UPLOAD_STAGES } from "constants/upload";
import UploadProgressContext from "contexts/uploadProgress";
import { useContext } from "react";

export function UploadProgressBar() {
    const { uploadStage, percentComplete } = useContext(UploadProgressContext);
    return (
        <Box>
            {(uploadStage === UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES ||
                uploadStage === UPLOAD_STAGES.EXTRACTING_METADATA ||
                uploadStage === UPLOAD_STAGES.UPLOADING) && (
                <>
                    <LinearProgress
                        sx={{
                            height: "2px",
                            backgroundColor: "transparent",
                        }}
                        variant="determinate"
                        value={percentComplete}
                    />
                    <Divider />
                </>
            )}
        </Box>
    );
}
