import React from 'react';
import {
    Box,
    CircularProgress,
    LinearProgress,
    Paper,
    Typography,
} from '@mui/material';
import Container, { SpaceBetweenFlex } from 'components/Container';
import { UserDetails } from 'types/user';
import constants from 'utils/strings/constants';
import { formatDateShort } from 'utils/time';
import { convertBytesToHumanReadable } from 'utils/billing';

interface Iprops {
    userDetails: UserDetails;
}

export default function SubscriptionDetails({ userDetails }: Iprops) {
    return (
        <Paper component={Box} bgcolor="accent.main" position={'relative'}>
            {userDetails ? (
                <>
                    <Box padding={2}>
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
                    <Paper
                        component={Box}
                        position={'relative'}
                        zIndex="2"
                        bgcolor="accent.dark"
                        padding={2}>
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
                    </Paper>
                </>
            ) : (
                <Container>
                    <CircularProgress />
                </Container>
            )}
        </Paper>
    );
}
