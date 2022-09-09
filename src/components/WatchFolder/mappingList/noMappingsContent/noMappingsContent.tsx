import { Stack, Typography } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';
import { NoMappingsContainer } from '../../styledComponents';
import { FlexWrapper } from 'components/Container';
import { CheckmarkIcon } from './checkmarkIcon';

export function NoMappingsContent() {
    return (
        <NoMappingsContainer>
            <Stack spacing={1}>
                <Typography variant="h4" fontWeight={'bold'}>
                    {constants.NO_FOLDERS_ADDED}
                </Typography>
                <Typography py={0.5} variant={'body2'} color="text.secondary">
                    {constants.FOLDERS_AUTOMATICALLY_MONITORED}
                </Typography>
                <Typography variant={'body2'} color="text.secondary">
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {constants.UPLOAD_NEW_FILES_TO_ENTE}
                    </FlexWrapper>
                </Typography>
                <Typography variant={'body2'} color="text.secondary">
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {constants.REMOVE_DELETED_FILES_FROM_ENTE}
                    </FlexWrapper>
                </Typography>
            </Stack>
        </NoMappingsContainer>
    );
}
