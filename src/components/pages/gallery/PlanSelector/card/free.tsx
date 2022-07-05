import { Stack } from '@mui/material';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import React from 'react';
import constants from 'utils/strings/constants';
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
    return (
        <>
            <Typography variant="h3" fontWeight={'bold'}>
                {constants.CHOOSE_PLAN}
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
                            {constants.TWO_MONTHS_FREE}
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
