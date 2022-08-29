import Close from '@mui/icons-material/Close';
import { IconButton, Stack } from '@mui/material';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { convertBytesToGBs, isSubscriptionCancelled } from 'utils/billing';
import constants from 'utils/strings/constants';
import { ManageSubscription } from '../manageSubscription';
import { PeriodToggler } from '../periodToggler';
import Plans from '../plans';

export default function PaidSubscriptionPlanSelectorCard({
    plans,
    subscription,
    closeModal,
    usage,
    planPeriod,
    togglePeriod,
    onPlanSelect,
    setLoading,
}) {
    return (
        <>
            <Box pl={1.5} py={0.5}>
                <SpaceBetweenFlex>
                    <Box>
                        <Typography variant="h3" fontWeight={'bold'}>
                            {constants.SUBSCRIPTION}
                        </Typography>
                        <Typography variant="body2" color={'text.secondary'}>
                            {convertBytesToGBs(subscription.storage, 2)}{' '}
                            {constants.GB}
                        </Typography>
                    </Box>
                    <IconButton onClick={closeModal} color="secondary">
                        <Close />
                    </IconButton>
                </SpaceBetweenFlex>
            </Box>

            <Box px={1.5}>
                <Typography color={'text.secondary'} fontWeight={'bold'}>
                    {constants.CURRENT_USAGE(
                        `${convertBytesToGBs(usage, 2)} ${constants.GB}`
                    )}
                </Typography>
            </Box>

            <Box>
                <Stack
                    spacing={3}
                    border={(theme) => `1px solid ${theme.palette.divider}`}
                    p={1.5}
                    borderRadius={(theme) => `${theme.shape.borderRadius}px`}>
                    <Box>
                        <PeriodToggler
                            planPeriod={planPeriod}
                            togglePeriod={togglePeriod}
                        />
                        <Typography
                            variant="body2"
                            mt={0.5}
                            color="text.secondary">
                            {constants.TWO_MONTHS_FREE}
                        </Typography>
                    </Box>
                    <Plans
                        plans={plans}
                        planPeriod={planPeriod}
                        onPlanSelect={onPlanSelect}
                        subscription={subscription}
                        closeModal={closeModal}
                    />
                </Stack>

                <Box py={1} px={1.5}>
                    <Typography color={'text.secondary'}>
                        {!isSubscriptionCancelled(subscription)
                            ? constants.RENEWAL_ACTIVE_SUBSCRIPTION_STATUS(
                                  subscription.expiryTime
                              )
                            : constants.RENEWAL_CANCELLED_SUBSCRIPTION_STATUS(
                                  subscription.expiryTime
                              )}
                    </Typography>
                </Box>
            </Box>

            <ManageSubscription
                subscription={subscription}
                closeModal={closeModal}
                setLoading={setLoading}
            />
        </>
    );
}
