import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import ArrowForward from "@mui/icons-material/ArrowForward";
import { Box, IconButton, Stack, Typography, styled } from "@mui/material";
import { PLAN_PERIOD } from "constants/gallery";
import { t } from "i18next";
import { Plan, Subscription } from "types/billing";
import { BonusData } from "types/user";
import {
    hasAddOnBonus,
    hasPaidSubscription,
    isPopularPlan,
    isUserSubscribedPlan,
} from "utils/billing";
import { PlanRow } from "./planRow";

interface Iprops {
    plans: Plan[];
    planPeriod: PLAN_PERIOD;
    subscription: Subscription;
    bonusData?: BonusData;
    onPlanSelect: (plan: Plan) => void;
    closeModal: () => void;
}

const Plans = ({
    plans,
    planPeriod,
    subscription,
    bonusData,
    onPlanSelect,
    closeModal,
}: Iprops) => (
    <Stack spacing={2}>
        {plans
            ?.filter((plan) => plan.period === planPeriod)
            ?.map((plan) => (
                <PlanRow
                    disabled={isUserSubscribedPlan(plan, subscription)}
                    popular={isPopularPlan(plan)}
                    key={plan.stripeID}
                    plan={plan}
                    subscription={subscription}
                    onPlanSelect={onPlanSelect}
                />
            ))}
        {!hasPaidSubscription(subscription) && !hasAddOnBonus(bonusData) && (
            <FreePlanRow closeModal={closeModal} />
        )}
    </Stack>
);

export default Plans;

interface FreePlanRowProps {
    closeModal: () => void;
}

const FreePlanRow: React.FC<FreePlanRowProps> = ({ closeModal }) => {
    return (
        <FreePlanRow_ onClick={closeModal}>
            <Box>
                <Typography> {t("FREE_PLAN_OPTION_LABEL")}</Typography>
                <Typography variant="small" color="text.muted">
                    {t("FREE_PLAN_DESCRIPTION")}
                </Typography>
            </Box>
            <IconButton className={"endIcon"}>
                <ArrowForward />
            </IconButton>
        </FreePlanRow_>
    );
};

const FreePlanRow_ = styled(SpaceBetweenFlex)(({ theme }) => ({
    gap: theme.spacing(1.5),
    padding: theme.spacing(1.5, 1),
    cursor: "pointer",
    "&:hover .endIcon": {
        backgroundColor: "rgba(255,255,255,0.08)",
    },
}));
