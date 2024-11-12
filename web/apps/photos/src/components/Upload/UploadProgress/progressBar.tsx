import { Box, Divider, LinearProgress } from "@mui/material";
import { useContext } from "react";
import UploadProgressContext from "./context";

export function UploadProgressBar() {
    const { uploadPhase, percentComplete } = useContext(UploadProgressContext);
    return (
        <Box>
            {(uploadPhase == "readingMetadata" ||
                uploadPhase == "uploading") && (
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
