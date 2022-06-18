import { PlanIconButton } from './button';
import { Typography } from '@mui/material';
import React from 'react';
import { isUserSubscribedPlan, convertBytesToGBs } from 'utils/billing';
import constants from 'utils/strings/constants';
import { PLAN_PERIOD } from '..';
import PlanTile from './planTile';

export function PlanCard({ plan, subscription, onPlanSelect }) {
    const handleClick = () => {
        !isUserSubscribedPlan(plan, subscription) && onPlanSelect(plan);
    };

    return (
        <PlanTile
            key={plan.stripeID}
            current={isUserSubscribedPlan(plan, subscription)}
            onClick={handleClick}>
            <Typography variant="title" fontWeight={900}>
                {convertBytesToGBs(plan.storage, 0)}
            </Typography>

            <Typography color="text.secondary" variant="title" fontWeight={500}>
                {`${plan.price} / ${
                    plan.period === PLAN_PERIOD.MONTH
                        ? constants.MONTH_SHORT
                        : constants.YEAR_SHORT
                }`}
            </Typography>

            <PlanIconButton
                current={isUserSubscribedPlan(plan, subscription)}
                onClick={handleClick}
            />
        </PlanTile>
    );
}
