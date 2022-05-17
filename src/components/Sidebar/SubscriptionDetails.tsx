import React from 'react';
import {
    Box,
    CircularProgress,
    LinearProgress,
    Typography,
} from '@mui/material';
import { FlexWrapper, SpaceBetweenFlex } from 'components/Container';
import { UserDetails } from 'types/user';
import constants from 'utils/strings/constants';
import { formatDateShort } from 'utils/time';
import { convertBytesToHumanReadable } from 'utils/billing';

interface Iprops {
    userDetails: UserDetails;
}
export default function SubscriptionDetails({ userDetails }: Iprops) {
    return (
        <Box
            display="flex"
            flexDirection={'column'}
            height={160}
            bgcolor="accent.main"
            position={'relative'}>
            {userDetails ? (
                <>
                    <Box
                        display="flex"
                        flexDirection={'column'}
                        padding="16px"
                        height="96px">
                        <SpaceBetweenFlex>
                            <Typography variant="subtitle2">
                                Current Plan
                            </Typography>
                            <Typography
                                variant="subtitle2"
                                sx={{ color: 'text.secondary' }}>
                                {`${constants.ENDS} ${formatDateShort(
                                    userDetails.subscription.expiryTime / 1000
                                )}`}
                            </Typography>
                        </SpaceBetweenFlex>
                        <Typography
                            sx={{ fontWeight: '700', fontSize: '24px' }}>
                            {convertBytesToHumanReadable(
                                userDetails.subscription.storage,
                                0
                            )}
                        </Typography>
                    </Box>
                    <Box
                        position={'absolute'}
                        right="17px"
                        top="10px"
                        component={'img'}
                        src="/images/locker.png"
                    />
                    <Box
                        position={'relative'}
                        zIndex="100"
                        height="64px"
                        bgcolor="accent.dark"
                        padding="16px">
                        <LinearProgress
                            sx={{ bgcolor: 'text.secondary' }}
                            variant="determinate"
                            value={
                                userDetails.usage /
                                userDetails.subscription.storage
                            }
                        />
                        <SpaceBetweenFlex style={{ marginTop: '8px' }}>
                            <Typography variant="caption">
                                {`${convertBytesToHumanReadable(
                                    userDetails.usage,
                                    1
                                )} of ${convertBytesToHumanReadable(
                                    userDetails.subscription.storage,
                                    0
                                )}`}
                            </Typography>
                            <Typography variant="caption">
                                {`${userDetails.fileCount} Photos`}
                            </Typography>
                        </SpaceBetweenFlex>
                    </Box>
                </>
            ) : (
                <FlexWrapper style={{ flex: '1', justifyContent: 'center' }}>
                    <CircularProgress />
                </FlexWrapper>
            )}
        </Box>
    );
}
