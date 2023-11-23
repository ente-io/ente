import React, { useContext } from 'react';
import Close from '@mui/icons-material/Close';
import { DialogTitle, Box, Typography, Stack } from '@mui/material';
import {
    IconButtonWithBG,
    SpaceBetweenFlex,
} from '@ente/shared/components/Container';
import { UPLOAD_STAGES } from 'constants/upload';
import { t } from 'i18next';

import UploadProgressContext from 'contexts/uploadProgress';
import UnfoldLessIcon from '@mui/icons-material/UnfoldLess';
import UnfoldMoreIcon from '@mui/icons-material/UnfoldMore';

const UploadProgressTitleText = ({ expanded }) => {
    return (
        <Typography variant={expanded ? 'h2' : 'h3'}>
            {t('FILE_UPLOAD')}
        </Typography>
    );
};

function UploadProgressSubtitleText() {
    const { uploadStage, uploadCounter } = useContext(UploadProgressContext);

    return (
        <Typography color="text.muted" marginTop={'4px'}>
            {uploadStage === UPLOAD_STAGES.UPLOADING
                ? t(`UPLOAD_STAGE_MESSAGE.${uploadStage}`, { uploadCounter })
                : uploadStage === UPLOAD_STAGES.EXTRACTING_METADATA
                ? t(`UPLOAD_STAGE_MESSAGE.${uploadStage}`, { uploadCounter })
                : t(`UPLOAD_STAGE_MESSAGE.${uploadStage}`)}
        </Typography>
    );
}

export function UploadProgressTitle() {
    const { setExpanded, onClose, expanded } = useContext(
        UploadProgressContext
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
                    <Stack direction={'row'} spacing={1}>
                        <IconButtonWithBG onClick={toggleExpanded}>
                            {expanded ? <UnfoldLessIcon /> : <UnfoldMoreIcon />}
                        </IconButtonWithBG>
                        <IconButtonWithBG onClick={onClose}>
                            <Close />
                        </IconButtonWithBG>
                    </Stack>
                </Box>
            </SpaceBetweenFlex>
        </DialogTitle>
    );
}
