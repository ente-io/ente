import { UPLOAD_STAGES } from "@/new/photos/services/upload/types";
import { Box, Divider, LinearProgress } from "@mui/material";
import { useContext } from "react";
import UploadProgressContext from "./context";

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
