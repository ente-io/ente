import React from 'react';
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

function UploadProgressSubtitleText(props) {
    return (
        <Typography color="text.secondary">
            {props.uploadStage === UPLOAD_STAGES.UPLOADING
                ? constants.UPLOAD_STAGE_MESSAGE[props.uploadStage](
                      props.fileCounter
                  )
                : constants.UPLOAD_STAGE_MESSAGE[props.uploadStage]}
        </Typography>
    );
}

export function UploadProgressTitle({
    setExpanded,
    expanded,
    handleClose,
    ...props
}) {
    const toggleExpanded = () => setExpanded((expanded) => !expanded);

    return (
        <DialogTitle>
            <SpaceBetweenFlex>
                <Box>
                    <UploadProgressTitleText expanded={expanded} />
                    <UploadProgressSubtitleText {...props} />
                </Box>
                <Box>
                    <Stack direction={'row'} spacing={1}>
                        <IconButtonWithBG onClick={toggleExpanded}>
                            {expanded ? <MinimizeIcon /> : <MaximizeIcon />}
                        </IconButtonWithBG>
                        <IconButtonWithBG onClick={handleClose}>
                            <Close />
                        </IconButtonWithBG>
                    </Stack>
                </Box>
            </SpaceBetweenFlex>
        </DialogTitle>
    );
}
