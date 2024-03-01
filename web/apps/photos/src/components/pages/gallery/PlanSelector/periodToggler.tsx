import { styled, ToggleButton, ToggleButtonGroup } from "@mui/material";
import { PLAN_PERIOD } from "constants/gallery";
import { t } from "i18next";

const CustomToggleButton = styled(ToggleButton)(({ theme }) => ({
    textTransform: "none",
    padding: "12px 16px",
    borderRadius: "4px",
    backgroundColor: theme.colors.fill.faint,
    border: `1px solid transparent`,
    color: theme.colors.text.faint,
    "&.Mui-selected": {
        backgroundColor: theme.colors.accent.A500,
        color: theme.colors.text.base,
    },
    "&.Mui-selected:hover": {
        backgroundColor: theme.colors.accent.A500,
        color: theme.colors.text.base,
    },
    width: "97.433px",
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
            color="primary"
        >
            <CustomToggleButton value={PLAN_PERIOD.MONTH}>
                {t("MONTHLY")}
            </CustomToggleButton>
            <CustomToggleButton value={PLAN_PERIOD.YEAR}>
                {t("YEARLY")}
            </CustomToggleButton>
        </ToggleButtonGroup>
    );
}
