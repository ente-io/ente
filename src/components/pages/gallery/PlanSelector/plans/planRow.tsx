import { Box, Button, Typography } from '@mui/material';
import React from 'react';
import { isUserSubscribedPlan, convertBytesToGBs } from 'utils/billing';
import constants from 'utils/strings/constants';
import { PLAN_PERIOD } from '..';
import { FlexWrapper, FluidContainer } from 'components/Container';
import ArrowForward from '@mui/icons-material/ArrowForward';

export function PlanRow({ plan, subscription, onPlanSelect }) {
    const handleClick = () => {
        !isUserSubscribedPlan(plan, subscription) && onPlanSelect(plan);
    };

    return (
        <FlexWrapper
            sx={{
                background:
                    'linear-gradient(268.22deg, rgba(256, 256, 256, 0.08) -3.72%, rgba(256, 256, 256, 0) 85.73%)',
            }}
            // current={isUserSubscribedPlan(plan, subscription)}
            onClick={handleClick}>
            <FluidContainer sx={{ '&&': { alignItems: 'flex-start' } }}>
                <Typography variant="h1" fontWeight={'bold'}>
                    {convertBytesToGBs(plan.storage, 0)}
                </Typography>
                <Typography variant="h3" color="text.secondary">
                    {constants.GB}
                </Typography>
            </FluidContainer>
            {/* <PlanIconButton
                current={isUserSubscribedPlan(plan, subscription)} */}
            <Button
                onClick={handleClick}
                sx={{ width: '136px' }}
                color="accent"
                endIcon={<ArrowForward />}>
                <Box>
                    <Typography fontWeight={'bold'} variant="h4">
                        {plan.price}{' '}
                    </Typography>{' '}
                    <Typography color="text.secondary" variant="body2">
                        / $
                        {plan.period === PLAN_PERIOD.MONTH
                            ? constants.MONTH_SHORT
                            : constants.YEAR_SHORT}
                    </Typography>
                </Box>
            </Button>
        </FlexWrapper>
    );
}
