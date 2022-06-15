import { Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { convertBytesToHumanReadable } from 'utils/billing';
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
                style={{
                    marginTop: '12px',
                }}>
                <Typography variant="caption">{`${convertBytesToHumanReadable(
                    userDetails.usage,
                    1
                )} ${constants.USED}`}</Typography>
                <Typography variant="caption" fontWeight={'bold'}>
                    {constants.PHOTO_COUNT(userDetails.fileCount)}
                </Typography>
            </SpaceBetweenFlex>
        </>
    );
}
