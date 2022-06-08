import React from 'react';
import {
    Box,
    CircularProgress,
    LinearProgress,
    Typography,
} from '@mui/material';
import Container, { SpaceBetweenFlex } from 'components/Container';
import { UserDetails } from 'types/user';
import constants from 'utils/strings/constants';
import { convertBytesToHumanReadable } from 'utils/billing';

import ChevronRightIcon from '@mui/icons-material/ChevronRight';
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
            // onClick={onManageClick}
        >
            <img
                style={{ position: 'absolute' }}
                src="/subscription-card-background.png"
            />
            {userDetails ? (
                <Box zIndex={1} position={'relative'} height={148}>
                    <Box padding={2}>
                        <Typography variant="body2">
                            {constants.STORAGE}
                        </Typography>

                        <Typography
                            fontWeight={'bold'}
                            sx={{ fontSize: '24px' }}>
                            {`${convertBytesToHumanReadable(
                                userDetails.usage,
                                1
                            )} of ${convertBytesToHumanReadable(
                                userDetails.subscription.storage,
                                0
                            )}`}
                        </Typography>
                    </Box>
                    <Box height={64} padding={2}>
                        <LinearProgress
                            sx={{
                                backgroundColor: 'rgba(255, 255, 255, 0.2)',
                                borderRadius: '4px',
                            }}
                            variant="determinate"
                            value={
                                (userDetails.usage * 100) /
                                userDetails.subscription.storage
                            }
                        />
                        <SpaceBetweenFlex style={{ marginTop: '12px' }}>
                            <Typography variant="caption">{`${convertBytesToHumanReadable(
                                userDetails.usage,
                                1
                            )} ${constants.USED}`}</Typography>
                            <Typography variant="caption" fontWeight={'bold'}>
                                {constants.PHOTO_COUNT(userDetails.fileCount)}
                            </Typography>
                        </SpaceBetweenFlex>
                    </Box>
                    <Box position={'absolute'} top={64} right={0}>
                        <ChevronRightIcon />
                    </Box>
                </Box>
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
