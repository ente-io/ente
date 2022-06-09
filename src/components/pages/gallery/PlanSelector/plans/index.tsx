import React from 'react';
import { isUserSubscribedPlan, convertBytesToGBs } from 'utils/billing';
import { PlanCard } from './planCard';

const Plans = ({ plans, planPeriod, subscription, onPlanSelect }) => (
    <div
        style={{
            display: 'flex',
            justifyContent: 'space-around',
            flexWrap: 'wrap',
            minHeight: '212px',
            margin: '5px 0',
        }}>
        {plans
            ?.filter((plan) => plan.period === planPeriod)
            ?.map((plan) => (
                <PlanCard
                    key={plan.stripeID}
                    isUserSubscribedPlan={isUserSubscribedPlan}
                    plan={plan}
                    subscription={subscription}
                    onPlanSelect={onPlanSelect}
                    convertBytesToGBs={convertBytesToGBs}
                />
            ))}
    </div>
);

export default Plans;
