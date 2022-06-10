import React, { useContext } from 'react';
import Close from '@mui/icons-material/Close';
import {
    DialogTitle,
    Box,
    Typography,
    IconButton,
    styled,
    Stack,
} from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import { UPLOAD_STAGES } from 'constants/upload';
import constants from 'utils/strings/constants';
import { MaximizeIcon } from 'components/icons/Maximize';
import { MinimizeIcon } from 'components/icons/Minimize';
import UploadProgressContext from 'contexts/uploadProgress';

const IconButtonWithBG = styled(IconButton)(({ theme }) => ({
    backgroundColor: theme.palette.secondary.main,
}));

const UploadProgressTitleText = ({ expanded }) => (
    <Typography
        {...(expanded ? { variant: 'title' } : {})}
        css={
            !expanded &&
            `
font-size: 24px;
font-weight: 600;
line-height: 36px;
`
        }>
        {constants.FILE_UPLOAD}
    </Typography>
);

function UploadProgressSubtitleText() {
    const { uploadStage, uploadCounter } = useContext(UploadProgressContext);

    return (
        <Typography color="text.secondary">
            {uploadStage === UPLOAD_STAGES.UPLOADING
                ? constants.UPLOAD_STAGE_MESSAGE[uploadStage](uploadCounter)
                : constants.UPLOAD_STAGE_MESSAGE[uploadStage]}
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
                            {expanded ? <MinimizeIcon /> : <MaximizeIcon />}
                        </IconButtonWithBG>
                        <IconButtonWithBG onClick={onClose.bind(null)}>
                            <Close />
                        </IconButtonWithBG>
                    </Stack>
                </Box>
            </SpaceBetweenFlex>
        </DialogTitle>
    );
}
