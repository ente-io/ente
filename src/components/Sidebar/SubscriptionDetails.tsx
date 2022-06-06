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
    closeSidebar: () => void;
}

export default function SubscriptionDetails({ userDetails }: Iprops) {
    // const { setDialogMessage } = useContext(AppContext);

    // async function onLeaveFamilyClick() {
    //     try {
    //         await billingService.leaveFamily();
    //         closeSidebar();
    //     } catch (e) {
    //         setDialogMessage({
    //             title: constants.ERROR,
    //             staticBackdrop: true,
    //             close: { variant: 'danger' },
    //             content: constants.UNKNOWN_ERROR,
    //         });
    //     }
    // }

    // const { showPlanSelectorModal } = useContext(GalleryContext);

    // function onManageClick() {
    //     closeSidebar();
    //     showPlanSelectorModal();
    // }
    return (
        <Box
            display="flex"
            flexDirection={'column'}
            height={160}
            bgcolor="accent.main"
            // position={'relative'}
            // onClick={onManageClick}
        >
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
                        zIndex="100"
                        height="64px"
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
        </Box>
    );
    {
        /* {!hasNonAdminFamilyMembers(userDetails.familyData) ||
            isFamilyAdmin(userDetails.familyData) ? (
                <div style={{ color: '#959595' }}>
                    {isSubscriptionActive(userDetails.subscription) ? (
                        isOnFreePlan(userDetails.subscription) ? (
                            constants.FREE_SUBSCRIPTION_INFO(
                                userDetails.subscription?.expiryTime
                            )
                        ) : isSubscriptionCancelled(
                              userDetails.subscription
                          ) ? (
                            constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                                userDetails.subscription?.expiryTime
                            )
                        ) : (
                            constants.RENEWAL_ACTIVE_SUBSCRIPTION_INFO(
                                userDetails.subscription?.expiryTime
                            )
                        )
                    ) : (
                        <p>{constants.SUBSCRIPTION_EXPIRED(onManageClick)}</p>
                    )}
                    <Button onClick={onManageClick}>
                        {isSubscribed(userDetails.subscription)
                            ? constants.MANAGE
                            : constants.SUBSCRIBE}
                    </Button>
                </div>
            ) : (
                <div style={{ color: '#959595' }}>
                    {constants.FAMILY_PLAN_MANAGE_ADMIN_ONLY(
                        getFamilyPlanAdmin(userDetails.familyData)?.email
                    )}
                    <Button
                        onClick={() =>
                            setDialogMessage({
                                title: `${constants.LEAVE_FAMILY}`,
                                content: constants.LEAVE_FAMILY_CONFIRM,
                                staticBackdrop: true,
                                proceed: {
                                    text: constants.LEAVE_FAMILY,
                                    action: onLeaveFamilyClick,
                                    variant: 'danger',
                                },
                                close: { text: constants.CANCEL },
                            })
                        }>
                        {constants.LEAVE_FAMILY}
                    </Button>
                </div>
            )}

            {hasNonAdminFamilyMembers(userDetails.familyData)
                ? constants.FAMILY_USAGE_INFO(
                      userDetails.usage,
                      convertBytesToHumanReadable(
                          getStorage(userDetails.familyData)
                      )
                  )
                : constants.USAGE_INFO(
                      userDetails.usage,
                      convertBytesToHumanReadable(
                          userDetails.subscription?.storage
                      )
                  )} */
    }
}
