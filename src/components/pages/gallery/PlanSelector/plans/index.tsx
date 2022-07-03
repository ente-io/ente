import { FreePlanRow } from './FreePlanRow';
import { Stack } from '@mui/material';
import React from 'react';
import {
    hasPaidSubscription,
    isPopularPlan,
    isUserSubscribedPlan,
} from 'utils/billing';
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
        {!hasPaidSubscription(subscription) && <FreePlanRow />}
    </Stack>
);

export default Plans;
