import { Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { makeHumanReadableStorage } from 'utils/billing';
import constants from 'utils/strings/constants';
import { Progressbar } from '../../styledComponents';

export function IndividualUsageSection({ userDetails }) {
    return (
        <>
            <Progressbar
                value={
                    (userDetails.usage * 100) / userDetails.subscription.storage
                }
            />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}>
                <Typography variant="caption">{`${makeHumanReadableStorage(
                    userDetails.usage,
                    'round-up'
                )} ${constants.USED}`}</Typography>
                <Typography variant="caption" fontWeight={'bold'}>
                    {constants.PHOTO_COUNT(userDetails.fileCount ?? 0)}
                </Typography>
            </SpaceBetweenFlex>
        </>
    );
}
