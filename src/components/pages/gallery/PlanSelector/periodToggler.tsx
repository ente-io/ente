import { styled, ToggleButton, ToggleButtonGroup } from '@mui/material';
import { PLAN_PERIOD } from 'constants/gallery';
import React from 'react';
import constants from 'utils/strings/constants';

const CustomToggleButton = styled(ToggleButton)(({ theme }) => ({
    textTransform: 'none',
    padding: '12px 16px',
    borderRadius: '4px',
    backgroundColor: theme.palette.fill.dark,
    border: `1px solid transparent`,
    color: theme.palette.text.disabled,
    '&.Mui-selected': {
        backgroundColor: theme.palette.accent.main,
        color: theme.palette.accent.contrastText,
    },
    '&.Mui-selected:hover': {
        backgroundColor: theme.palette.accent.main,
        color: theme.palette.accent.contrastText,
    },
    width: '97.433px',
}));

export function PeriodToggler({ planPeriod, togglePeriod }) {
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
