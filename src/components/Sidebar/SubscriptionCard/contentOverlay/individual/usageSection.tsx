import { Box, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { makeHumanReadableStorage } from 'utils/billing';
import constants from 'utils/strings/constants';
import { Progressbar } from '../../styledComponents';

interface Iprops {
    usage: number;
    fileCount: number;
    storage: number;
}
export function IndividualUsageSection({ usage, storage, fileCount }: Iprops) {
    return (
        <Box width="100%">
            <Progressbar value={(usage * 100) / storage} />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}>
                <Typography variant="caption">{`${makeHumanReadableStorage(
                    storage - usage
                )} ${constants.FREE}`}</Typography>
                <Typography variant="caption" fontWeight={'bold'}>
                    {constants.PHOTO_COUNT(fileCount ?? 0)}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
}
