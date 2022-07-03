import ArrowForward from '@mui/icons-material/ArrowForward';
import { Box, Stack, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import {
    hasPaidSubscription,
    isPopularPlan,
    isUserSubscribedPlan,
} from 'utils/billing';
import constants from 'utils/strings/constants';
import { PlanRow } from './planRow';

const Plans = ({ plans, planPeriod, subscription, onPlanSelect }) => (
    <Stack spacing={2}>
        {plans
            ?.filter((plan) => plan.period === planPeriod)
            ?.map((plan) => (
                <PlanRow
                    disabled={isUserSubscribedPlan(plan, subscription)}
                    popular={isPopularPlan(plan)}
                    key={plan.stripeID}
                    plan={plan}
                    subscription={subscription}
                    onPlanSelect={onPlanSelect}
                />
            ))}
        {!hasPaidSubscription(subscription) && (
            <SpaceBetweenFlex
                gap={1.5}
                py={1.5}
                pr={1}
                sx={{ cursor: 'pointer' }}>
                <Box>
                    <Typography> {constants.FREE_PLAN_OPTION_LABEL}</Typography>
                    <Typography variant="body2" color="text.secondary">
                        {constants.FREE_PLAN_DESCRIPTION}
                    </Typography>
                </Box>
                <Box>
                    <ArrowForward />
                </Box>
            </SpaceBetweenFlex>
        )}
    </Stack>
);

export default Plans;
