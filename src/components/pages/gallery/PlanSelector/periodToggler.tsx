import { styled, ToggleButton, ToggleButtonGroup } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';
import { PLAN_PERIOD } from '.';
export function PeriodToggler({ planPeriod, togglePeriod }) {
    const CustomToggleButton = styled(ToggleButton)(({ theme }) => ({
        textTransform: 'none',
        padding: '12px 16px',
        borderRadius: '4px',
        backgroundColor: theme.palette.fill.dark,
        color: theme.palette.text.disabled,
        '&.Mui-selected': {
            backgroundColor: theme.palette.accent.main,
            color: theme.palette.primary.contrastText,
        },
        '&.Mui-selected:hover': {
            backgroundColor: theme.palette.accent.main,
            color: theme.palette.primary.contrastText,
        },
    }));

    const handleChange = (_, newPlanPeriod: PLAN_PERIOD) => {
        if (newPlanPeriod !== null && newPlanPeriod !== planPeriod) {
            togglePeriod();
        }
    };

    return (
        <ToggleButtonGroup
            value={planPeriod}
            exclusive
            onChange={handleChange}
            color="primary">
            <CustomToggleButton value={PLAN_PERIOD.MONTH}>
                {constants.MONTHLY}
            </CustomToggleButton>
            <CustomToggleButton value={PLAN_PERIOD.YEAR}>
                {constants.YEARLY}
            </CustomToggleButton>
        </ToggleButtonGroup>
    );
}
