import { Box, Button, ButtonProps, styled, Typography } from '@mui/material';
import React from 'react';
import {
    isUserSubscribedPlan,
    convertBytesToGBs,
    hasPaidSubscription,
} from 'utils/billing';
import { FlexWrapper, FluidContainer } from 'components/Container';
import ArrowForward from '@mui/icons-material/ArrowForward';
import { PLAN_PERIOD } from 'constants/gallery';
import Done from '@mui/icons-material/Done';
import { Plan, Subscription } from 'types/billing';
import { Badge } from 'components/Badge';
import { t } from 'i18next';

interface Iprops {
    plan: Plan;
    subscription: Subscription;
    onPlanSelect: (plan: Plan) => void;
    disabled: boolean;
    popular: boolean;
}

const PlanRowContainer = styled(FlexWrapper)(() => ({
    background:
        'linear-gradient(268.22deg, rgba(256, 256, 256, 0.08) -3.72%, rgba(256, 256, 256, 0) 85.73%)',
}));

const TopAlignedFluidContainer = styled(FluidContainer)`
    align-items: flex-start;
`;

const DisabledPlanButton = styled((props: ButtonProps) => (
    <Button disabled endIcon={<Done />} {...props} />
))(({ theme }) => ({
    '&.Mui-disabled': {
        backgroundColor: 'transparent',
        color: theme.colors.text.base,
    },
}));

const ActivePlanButton = styled((props: ButtonProps) => (
    <Button color="accent" {...props} endIcon={<ArrowForward />} />
))(() => ({
    '.MuiButton-endIcon': {
        transition: 'transform .2s ease-in-out',
    },
    '&:hover .MuiButton-endIcon': {
        transform: 'translateX(4px)',
    },
}));

export function PlanRow({
    plan,
    subscription,
    onPlanSelect,
    disabled,
    popular,
}: Iprops) {
    const handleClick = () => {
        !isUserSubscribedPlan(plan, subscription) && onPlanSelect(plan);
    };

    const PlanButton = disabled ? DisabledPlanButton : ActivePlanButton;

    return (
        <PlanRowContainer>
            <TopAlignedFluidContainer>
                <Typography variant="h1" fontWeight={'bold'}>
                    {convertBytesToGBs(plan.storage)}
                </Typography>
                <FlexWrapper flexWrap={'wrap'} gap={1}>
                    <Typography variant="h3" color="text.muted">
                        {t('GB')}
                    </Typography>
                    {popular && !hasPaidSubscription(subscription) && (
                        <Badge>{t('POPULAR')}</Badge>
                    )}
                </FlexWrapper>
            </TopAlignedFluidContainer>
            <Box width="136px">
                <PlanButton
                    sx={{
                        justifyContent: 'flex-end',
                        borderTopLeftRadius: 0,
                        borderBottomLeftRadius: 0,
                    }}
                    size="large"
                    onClick={handleClick}>
                    <Box textAlign={'right'}>
                        <Typography fontWeight={'bold'} variant="large">
                            {plan.price}{' '}
                        </Typography>{' '}
                        <Typography color="text.muted" variant="small">
                            {`/ ${
                                plan.period === PLAN_PERIOD.MONTH
                                    ? t('MONTH_SHORT')
                                    : t('YEAR')
                            }`}
                        </Typography>
                    </Box>
                </PlanButton>
            </Box>
        </PlanRowContainer>
    );
}
