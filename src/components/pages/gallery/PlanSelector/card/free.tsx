import { Stack } from '@mui/material';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { PeriodToggler } from '../periodToggler';
import Plans from '../plans';

export default function FreeSubscriptionPlanSelectorCard({
    plans,
    subscription,
    closeModal,
    planPeriod,
    togglePeriod,
    onPlanSelect,
}) {
    const { t } = useTranslation();

    return (
        <>
            <Typography variant="h3" fontWeight={'bold'}>
                {t('CHOOSE_PLAN')}
            </Typography>

            <Box>
                <Stack spacing={3}>
                    <Box>
                        <PeriodToggler
                            planPeriod={planPeriod}
                            togglePeriod={togglePeriod}
                        />
                        <Typography
                            variant="body2"
                            mt={0.5}
                            color="text.secondary">
                            {t('TWO_MONTHS_FREE')}
                        </Typography>
                    </Box>
                    <Plans
                        plans={plans}
                        planPeriod={planPeriod}
                        onPlanSelect={onPlanSelect}
                        subscription={subscription}
                        closeModal={closeModal}
                    />
                </Stack>
            </Box>
        </>
    );
}
