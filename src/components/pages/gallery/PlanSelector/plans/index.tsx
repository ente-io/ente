import { CenteredFlex } from 'components/Container';
import React from 'react';
import { PlanCard } from './planCard';

const Plans = ({ plans, planPeriod, subscription, onPlanSelect }) => (
    <CenteredFlex
        mt={4}
        sx={{
            flexWrap: 'wrap',
            minHeight: '228px',
        }}>
        {plans
            ?.filter((plan) => plan.period === planPeriod)
            ?.map((plan) => (
                <PlanCard
                    key={plan.stripeID}
                    plan={plan}
                    subscription={subscription}
                    onPlanSelect={onPlanSelect}
                />
            ))}
    </CenteredFlex>
);

export default Plans;
