import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { PlanTile } from './planTile';

export function PlanCard({
    isUserSubscribedPlan,
    plan,
    subscription,
    onPlanSelect,
    convertBytesToGBs,
}) {
    return (
        <PlanTile
            key={plan.stripeID}
            className="subscription-plan-selector"
            currentlySubscribed={isUserSubscribedPlan(plan, subscription)}
            onClick={
                isUserSubscribedPlan(plan, subscription)
                    ? () => {}
                    : async () => await onPlanSelect(plan)
            }>
            <div>
                <span
                    style={{
                        color: '#ECECEC',
                        fontWeight: 900,
                        fontSize: '40px',
                        lineHeight: '40px',
                    }}>
                    {convertBytesToGBs(plan.storage, 0)}
                </span>
                <span
                    style={{
                        color: '#858585',
                        fontSize: '24px',
                        fontWeight: 900,
                    }}>
                    {' '}
                    GB
                </span>
            </div>
            <div
                className="bold-text"
                style={{
                    color: '#aaa',
                    lineHeight: '36px',
                    fontSize: '20px',
                }}>
                {`${plan.price} / ${plan.period}`}
            </div>
            <Button
                variant="outline-success"
                block
                style={{
                    marginTop: '20px',
                    fontSize: '14px',
                    display: 'flex',
                    justifyContent: 'center',
                }}
                disabled={isUserSubscribedPlan(plan, subscription)}>
                {constants.CHOOSE_PLAN_BTN}
                <ArrowForwardIcon
                    style={{
                        marginLeft: '5px',
                    }}
                />
            </Button>
        </PlanTile>
    );
}
