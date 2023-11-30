import { Stack } from '@mui/material';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import React from 'react';
import { t } from 'i18next';
import { PeriodToggler } from '../periodToggler';
import Plans from '../plans';
import { hasAddOnBonus } from 'utils/billing';
import { BFAddOnRow } from '../plans/BfAddOnRow';
import { ManageSubscription } from '../manageSubscription';

export default function FreeSubscriptionPlanSelectorCard({
    plans,
    subscription,
    bonusData,
    closeModal,
    setLoading,
    planPeriod,
    togglePeriod,
    onPlanSelect,
}) {
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
                        <Typography variant="small" mt={0.5} color="text.muted">
                            {t('TWO_MONTHS_FREE')}
                        </Typography>
                    </Box>
                    <Plans
                        plans={plans}
                        planPeriod={planPeriod}
                        onPlanSelect={onPlanSelect}
                        subscription={subscription}
                        bonusData={bonusData}
                        closeModal={closeModal}
                    />
                    {hasAddOnBonus(bonusData) && (
                        <BFAddOnRow
                            bonusData={bonusData}
                            closeModal={closeModal}
                        />
                    )}
                    {hasAddOnBonus(bonusData) && (
                        <ManageSubscription
                            subscription={subscription}
                            bonusData={bonusData}
                            closeModal={closeModal}
                            setLoading={setLoading}
                        />
                    )}
                </Stack>
            </Box>
        </>
    );
}
