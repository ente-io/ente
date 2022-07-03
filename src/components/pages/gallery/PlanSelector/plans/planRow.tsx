import { Box, Button, ButtonProps, styled, Typography } from '@mui/material';
import React from 'react';
import { isUserSubscribedPlan, convertBytesToGBs } from 'utils/billing';
import constants from 'utils/strings/constants';
import { FlexWrapper, FluidContainer } from 'components/Container';
import ArrowForward from '@mui/icons-material/ArrowForward';
import { PLAN_PERIOD } from 'constants/gallery';
import Done from '@mui/icons-material/Done';
import { Plan, Subscription } from 'types/billing';

interface Iprops {
    plan: Plan;
    subscription: Subscription;
    onPlanSelect: (plan: Plan) => void;
    disabled: boolean;
}
const DisabledPlanButton = styled((props: ButtonProps) => (
    <Button disabled endIcon={<Done />} {...props} />
))(({ theme }) => ({
    '&&': {
        cursor: 'default',
        backgroundColor: 'transparent',
        color: theme.palette.text.primary,
    },
}));

const ActivePlanButton = (props: ButtonProps) => (
    <Button color="accent" {...props} endIcon={<ArrowForward />} />
);

export function PlanRow({
    plan,
    subscription,
    onPlanSelect,
    disabled,
}: Iprops) {
    const handleClick = () => {
        !isUserSubscribedPlan(plan, subscription) && onPlanSelect(plan);
    };

    const PlanButton = disabled ? DisabledPlanButton : ActivePlanButton;

    return (
        <FlexWrapper
            sx={{
                background:
                    'linear-gradient(268.22deg, rgba(256, 256, 256, 0.08) -3.72%, rgba(256, 256, 256, 0) 85.73%)',
            }}
            onClick={handleClick}>
            <FluidContainer sx={{ '&&': { alignItems: 'flex-start' } }}>
                <Typography variant="h1" fontWeight={'bold'}>
                    {convertBytesToGBs(plan.storage)}
                </Typography>
                <Typography variant="h3" color="text.secondary">
                    {constants.GB}
                </Typography>
            </FluidContainer>
            <Box width="136px">
                <PlanButton size="large" onClick={handleClick}>
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
                </PlanButton>
            </Box>
        </FlexWrapper>
    );
}
