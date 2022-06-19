import { Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';
import constants from 'utils/strings/constants';
import { CheckmarkIcon } from './checkmarkIcon';
import { NoMappingsContainer } from './styledComponents';
export function NoMappingsContent() {
    return (
        <NoMappingsContainer>
            <Typography variant="subtitle" mb={2}>
                {constants.NO_FOLDERS_ADDED}
            </Typography>
            <Typography mb={1}>
                {constants.FOLDERS_AUTOMATICALLY_MONITORED}
            </Typography>
            <FlexWrapper>
                <CheckmarkIcon /> {constants.UPLOAD_NEW_FILES_TO_ENTE}
            </FlexWrapper>
            <FlexWrapper>
                <CheckmarkIcon /> {constants.REMOVE_DELETED_FILES_FROM_ENTE}
            </FlexWrapper>
        </NoMappingsContainer>
    );
}
