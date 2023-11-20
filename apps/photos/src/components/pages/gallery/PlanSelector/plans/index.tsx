import { FreePlanRow } from './FreePlanRow';
import { Stack } from '@mui/material';
import React from 'react';
import {
    hasAddOnBonus,
    hasPaidSubscription,
    isPopularPlan,
    isUserSubscribedPlan,
} from 'utils/billing';
import { PlanRow } from './planRow';
import { Plan, Subscription } from 'types/billing';
import { PLAN_PERIOD } from 'constants/gallery';
import { BonusData } from 'types/user';

interface Iprops {
    plans: Plan[];
    planPeriod: PLAN_PERIOD;
    subscription: Subscription;
    bonusData?: BonusData;
    onPlanSelect: (plan: Plan) => void;
    closeModal: () => void;
}

const Plans = ({
    plans,
    planPeriod,
    subscription,
    bonusData,
    onPlanSelect,
    closeModal,
}: Iprops) => (
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
        {!hasPaidSubscription(subscription) && !hasAddOnBonus(bonusData) && (
            <FreePlanRow closeModal={closeModal} />
        )}
    </Stack>
);

export default Plans;
