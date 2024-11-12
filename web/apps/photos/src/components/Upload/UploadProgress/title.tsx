import { FilledIconButton } from "@/new/photos/components/mui";
import { type UploadPhase } from "@/new/photos/services/upload/types";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import Close from "@mui/icons-material/Close";
import UnfoldLessIcon from "@mui/icons-material/UnfoldLess";
import UnfoldMoreIcon from "@mui/icons-material/UnfoldMore";
import { Box, DialogTitle, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useContext } from "react";
import type { UploadCounter } from "services/upload/uploadManager";
import UploadProgressContext from "./context";

const UploadProgressTitleText = ({ expanded }) => {
    return (
        <Typography variant={expanded ? "h2" : "h3"}>
            {t("FILE_UPLOAD")}
        </Typography>
    );
};

function UploadProgressSubtitleText() {
    const { uploadPhase, uploadCounter } = useContext(UploadProgressContext);

    return (
        <Typography
            variant="body"
            fontWeight={"normal"}
            color="text.muted"
            marginTop={"4px"}
        >
            {subtitleText(uploadPhase, uploadCounter)}
        </Typography>
    );
}

const subtitleText = (
    uploadPhase: UploadPhase,
    uploadCounter: UploadCounter,
) => {
    switch (uploadPhase) {
        case "preparing":
            return t("UPLOAD_STAGE_MESSAGE.0");
        case "readingMetadata":
            return t("UPLOAD_STAGE_MESSAGE.1");
        case "uploading":
            return t("UPLOAD_STAGE_MESSAGE.3", { uploadCounter });
        case "cancelling":
            return t("UPLOAD_STAGE_MESSAGE.4");
        case "done":
            return t("UPLOAD_STAGE_MESSAGE.5");
    }
};

export function UploadProgressTitle() {
    const { setExpanded, onClose, expanded } = useContext(
        UploadProgressContext,
    );
    const toggleExpanded = () => setExpanded((expanded) => !expanded);

    return (
        <DialogTitle>
            <SpaceBetweenFlex>
                <Box>
                    <UploadProgressTitleText expanded={expanded} />
                    <UploadProgressSubtitleText />
                </Box>
                <Box>
                    <Stack direction={"row"} spacing={1}>
                        <FilledIconButton onClick={toggleExpanded}>
                            {expanded ? <UnfoldLessIcon /> : <UnfoldMoreIcon />}
                        </FilledIconButton>
                        <FilledIconButton onClick={onClose}>
                            <Close />
                        </FilledIconButton>
                    </Stack>
                </Box>
            </SpaceBetweenFlex>
        </DialogTitle>
    );
}
