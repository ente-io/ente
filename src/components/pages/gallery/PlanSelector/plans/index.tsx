import React from 'react';
import { PlanCard } from './planCard';

const Plans = ({ plans, planPeriod, subscription, onPlanSelect }) => (
    <div
        style={{
            display: 'flex',
            justifyContent: 'space-around',
            flexWrap: 'wrap',
            minHeight: '230px',
            marginTop: '32px',
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
    </div>
);

export default Plans;
