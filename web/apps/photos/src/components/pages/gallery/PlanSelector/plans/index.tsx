import { bytesInGB, formattedStorageByteSize } from "@/new/photos/utils/units";
import {
    FlexWrapper,
    FluidContainer,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import ArrowForward from "@mui/icons-material/ArrowForward";
import Done from "@mui/icons-material/Done";
import {
    Box,
    Button,
    ButtonProps,
    IconButton,
    Stack,
    Typography,
    styled,
} from "@mui/material";
import { PLAN_PERIOD } from "constants/gallery";
import { t } from "i18next";
import type { PlansResponse } from "services/billingService";
import { Plan, Subscription } from "types/billing";
import { BonusData } from "types/user";
import {
    hasAddOnBonus,
    hasPaidSubscription,
    isPopularPlan,
    isUserSubscribedPlan,
} from "utils/billing";

interface PlansProps {
    plansResponse: PlansResponse | undefined;
    planPeriod: PLAN_PERIOD;
    subscription: Subscription;
    bonusData?: BonusData;
    onPlanSelect: (plan: Plan) => void;
    closeModal: () => void;
}

const Plans = ({
    plansResponse,
    planPeriod,
    subscription,
    bonusData,
    onPlanSelect,
    closeModal,
}: PlansProps) => {
    const { freePlan, plans } = plansResponse ?? {};
    return (
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
            {!hasPaidSubscription(subscription) &&
                !hasAddOnBonus(bonusData) &&
                freePlan && (
                    <FreePlanRow
                        storage={freePlan.storage}
                        closeModal={closeModal}
                    />
                )}
        </Stack>
    );
};

export default Plans;

interface PlanRowProps {
    plan: Plan;
    subscription: Subscription;
    onPlanSelect: (plan: Plan) => void;
    disabled: boolean;
    popular: boolean;
}

function PlanRow({
    plan,
    subscription,
    onPlanSelect,
    disabled,
    popular,
}: PlanRowProps) {
    const handleClick = () => {
        !isUserSubscribedPlan(plan, subscription) && onPlanSelect(plan);
    };

    const PlanButton = disabled ? DisabledPlanButton : ActivePlanButton;

    return (
        <PlanRowContainer>
            <TopAlignedFluidContainer>
                <Typography variant="h1" fontWeight={"bold"}>
                    {bytesInGB(plan.storage)}
                </Typography>
                <FlexWrapper flexWrap={"wrap"} gap={1}>
                    <Typography variant="h3" color="text.muted">
                        {t("storage_unit.gb")}
                    </Typography>
                    {popular && !hasPaidSubscription(subscription) && (
                        <Badge>{t("POPULAR")}</Badge>
                    )}
                </FlexWrapper>
            </TopAlignedFluidContainer>
            <Box width="136px">
                <PlanButton
                    sx={{
                        justifyContent: "flex-end",
                        borderTopLeftRadius: 0,
                        borderBottomLeftRadius: 0,
                    }}
                    size="large"
                    onClick={handleClick}
                >
                    <Box textAlign={"right"}>
                        <Typography fontWeight={"bold"} variant="large">
                            {plan.price}{" "}
                        </Typography>{" "}
                        <Typography color="text.muted" variant="small">
                            {`/ ${
                                plan.period === PLAN_PERIOD.MONTH
                                    ? t("MONTH_SHORT")
                                    : t("YEAR")
                            }`}
                        </Typography>
                    </Box>
                </PlanButton>
            </Box>
        </PlanRowContainer>
    );
}

const PlanRowContainer = styled(FlexWrapper)(() => ({
    background:
        "linear-gradient(268.22deg, rgba(256, 256, 256, 0.08) -3.72%, rgba(256, 256, 256, 0) 85.73%)",
}));

const TopAlignedFluidContainer = styled(FluidContainer)`
    align-items: flex-start;
`;

const DisabledPlanButton = styled((props: ButtonProps) => (
    <Button disabled endIcon={<Done />} {...props} />
))(({ theme }) => ({
    "&.Mui-disabled": {
        backgroundColor: "transparent",
        color: theme.colors.text.base,
    },
}));

const ActivePlanButton = styled((props: ButtonProps) => (
    <Button color="accent" {...props} endIcon={<ArrowForward />} />
))(() => ({
    ".MuiButton-endIcon": {
        transition: "transform .2s ease-in-out",
    },
    "&:hover .MuiButton-endIcon": {
        transform: "translateX(4px)",
    },
}));

const Badge = styled(Box)(({ theme }) => ({
    borderRadius: theme.shape.borderRadius,
    padding: "2px 4px",
    backgroundColor: theme.colors.black.muted,
    backdropFilter: `blur(${theme.colors.blur.muted})`,
    color: theme.colors.white.base,
    textTransform: "uppercase",
    ...theme.typography.mini,
}));

interface FreePlanRowProps {
    storage: number;
    closeModal: () => void;
}

const FreePlanRow: React.FC<FreePlanRowProps> = ({ closeModal, storage }) => {
    return (
        <FreePlanRow_ onClick={closeModal}>
            <Box>
                <Typography>{t("free_plan_option")}</Typography>
                <Typography variant="small" color="text.muted">
                    {t("free_plan_description", {
                        storage: formattedStorageByteSize(storage),
                    })}
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
