import log from "@/base/log";
import { bytesInGB, formattedStorageByteSize } from "@/new/photos/utils/units";
import {
    FlexWrapper,
    FluidContainer,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import ArrowForward from "@mui/icons-material/ArrowForward";
import ChevronRight from "@mui/icons-material/ChevronRight";
import Close from "@mui/icons-material/Close";
import Done from "@mui/icons-material/Done";
import {
    Button,
    ButtonProps,
    Dialog,
    IconButton,
    Link,
    Stack,
    styled,
    ToggleButton,
    ToggleButtonGroup,
    useMediaQuery,
    useTheme,
} from "@mui/material";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import { PLAN_PERIOD } from "constants/gallery";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";
import billingService, { type PlansResponse } from "services/billingService";
import { Plan, Subscription } from "types/billing";
import { SetLoading } from "types/gallery";
import { BonusData } from "types/user";
import {
    activateSubscription,
    cancelSubscription,
    getLocalUserSubscription,
    hasAddOnBonus,
    hasPaidSubscription,
    hasStripeSubscription,
    isOnFreePlan,
    isPopularPlan,
    isSubscriptionActive,
    isSubscriptionCancelled,
    isUserSubscribedPlan,
    manageFamilyMethod,
    planForSubscription,
    planSelectionOutcome,
    updatePaymentMethod,
    updateSubscription,
} from "utils/billing";
import { getLocalUserDetails } from "utils/user";
import { getTotalFamilyUsage, isPartOfFamily } from "utils/user/family";

interface PlanSelectorProps {
    modalView: boolean;
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelector(props: PlanSelectorProps) {
    const fullScreen = useMediaQuery(useTheme().breakpoints.down("sm"));

    if (!props.modalView) {
        return <></>;
    }

    return (
        <Dialog
            {...{ fullScreen }}
            open={props.modalView}
            onClose={props.closeModal}
            PaperProps={{
                sx: (theme) => ({
                    width: { sm: "391px" },
                    p: 1,
                    [theme.breakpoints.down(360)]: { p: 0 },
                }),
            }}
        >
            <PlanSelectorCard
                closeModal={props.closeModal}
                setLoading={props.setLoading}
            />
        </Dialog>
    );
}

export default PlanSelector;

interface PlanSelectorCardProps {
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelectorCard(props: PlanSelectorCardProps) {
    const subscription = useMemo(() => getLocalUserSubscription(), []);
    const [plansResponse, setPlansResponse] = useState<
        PlansResponse | undefined
    >();

    const [planPeriod, setPlanPeriod] = useState<PLAN_PERIOD>(
        subscription?.period || PLAN_PERIOD.MONTH,
    );
    const galleryContext = useContext(GalleryContext);
    const appContext = useContext(AppContext);
    const bonusData = useMemo(() => {
        const userDetails = getLocalUserDetails();
        if (!userDetails) {
            return null;
        }
        return userDetails.bonusData;
    }, []);

    const usage = useMemo(() => {
        const userDetails = getLocalUserDetails();
        if (!userDetails) {
            return 0;
        }
        return isPartOfFamily(userDetails.familyData)
            ? getTotalFamilyUsage(userDetails.familyData)
            : userDetails.usage;
    }, []);

    const togglePeriod = () => {
        setPlanPeriod((prevPeriod) =>
            prevPeriod === PLAN_PERIOD.MONTH
                ? PLAN_PERIOD.YEAR
                : PLAN_PERIOD.MONTH,
        );
    };
    function onReopenClick() {
        appContext.closeMessageDialog();
        galleryContext.showPlanSelectorModal();
    }
    useEffect(() => {
        const main = async () => {
            try {
                props.setLoading(true);
                const response = await billingService.getPlans();
                const { plans } = response;
                if (isSubscriptionActive(subscription)) {
                    const planNotListed =
                        plans.filter((plan) =>
                            isUserSubscribedPlan(plan, subscription),
                        ).length === 0;
                    if (
                        subscription &&
                        !isOnFreePlan(subscription) &&
                        planNotListed
                    ) {
                        plans.push(planForSubscription(subscription));
                    }
                }
                setPlansResponse(response);
            } catch (e) {
                log.error("plan selector modal open failed", e);
                props.closeModal();
                appContext.setDialogMessage({
                    title: t("OPEN_PLAN_SELECTOR_MODAL_FAILED"),
                    content: t("UNKNOWN_ERROR"),
                    close: { text: t("CLOSE"), variant: "secondary" },
                    proceed: {
                        text: t("REOPEN_PLAN_SELECTOR_MODAL"),
                        variant: "accent",
                        action: onReopenClick,
                    },
                });
            } finally {
                props.setLoading(false);
            }
        };
        main();
    }, []);

    async function onPlanSelect(plan: Plan) {
        switch (planSelectionOutcome(subscription)) {
            case "buyPlan":
                try {
                    props.setLoading(true);
                    await billingService.buySubscription(plan.stripeID);
                } catch (e) {
                    props.setLoading(false);
                    appContext.setDialogMessage({
                        title: t("ERROR"),
                        content: t("SUBSCRIPTION_PURCHASE_FAILED"),
                        close: { variant: "critical" },
                    });
                }
                break;

            case "updateSubscriptionToPlan":
                appContext.setDialogMessage({
                    title: t("update_subscription_title"),
                    content: t("UPDATE_SUBSCRIPTION_MESSAGE"),
                    proceed: {
                        text: t("UPDATE_SUBSCRIPTION"),
                        action: updateSubscription.bind(
                            null,
                            plan,
                            appContext.setDialogMessage,
                            props.setLoading,
                            props.closeModal,
                        ),
                        variant: "accent",
                    },
                    close: { text: t("cancel") },
                });
                break;

            case "cancelOnMobile":
                appContext.setDialogMessage({
                    title: t("CANCEL_SUBSCRIPTION_ON_MOBILE"),
                    content: t("CANCEL_SUBSCRIPTION_ON_MOBILE_MESSAGE"),
                    close: { variant: "secondary" },
                });
                break;

            case "contactSupport":
                appContext.setDialogMessage({
                    title: t("MANAGE_PLAN"),
                    content: (
                        <Trans
                            i18nKey={"MAIL_TO_MANAGE_SUBSCRIPTION"}
                            components={{
                                a: <Link href="mailto:support@ente.io" />,
                            }}
                            values={{ emailID: "support@ente.io" }}
                        />
                    ),
                    close: { variant: "secondary" },
                });
                break;
        }
    }

    const { closeModal, setLoading } = props;

    const commonCardData = {
        subscription,
        bonusData,
        closeModal,
        planPeriod,
        togglePeriod,
        setLoading,
    };

    const plansList = (
        <Plans
            plansResponse={plansResponse}
            planPeriod={planPeriod}
            onPlanSelect={onPlanSelect}
            subscription={subscription}
            bonusData={bonusData}
            closeModal={closeModal}
        />
    );

    return (
        <>
            <Stack spacing={3} p={1.5}>
                {hasPaidSubscription(subscription) ? (
                    <PaidSubscriptionPlanSelectorCard
                        {...commonCardData}
                        usage={usage}
                    >
                        {plansList}
                    </PaidSubscriptionPlanSelectorCard>
                ) : (
                    <FreeSubscriptionPlanSelectorCard {...commonCardData}>
                        {plansList}
                    </FreeSubscriptionPlanSelectorCard>
                )}
            </Stack>
        </>
    );
}

function FreeSubscriptionPlanSelectorCard({
    children,
    subscription,
    bonusData,
    closeModal,
    setLoading,
    planPeriod,
    togglePeriod,
}) {
    return (
        <>
            <Typography variant="h3" fontWeight={"bold"}>
                {t("CHOOSE_PLAN")}
            </Typography>

            <Box>
                <Stack spacing={3}>
                    <Box>
                        <PeriodToggler
                            planPeriod={planPeriod}
                            togglePeriod={togglePeriod}
                        />
                        <Typography variant="small" mt={0.5} color="text.muted">
                            {t("TWO_MONTHS_FREE")}
                        </Typography>
                    </Box>
                    {children}
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

function PaidSubscriptionPlanSelectorCard({
    children,
    subscription,
    bonusData,
    closeModal,
    usage,
    planPeriod,
    togglePeriod,
    setLoading,
}) {
    return (
        <>
            <Box pl={1.5} py={0.5}>
                <SpaceBetweenFlex>
                    <Box>
                        <Typography variant="h3" fontWeight={"bold"}>
                            {t("SUBSCRIPTION")}
                        </Typography>
                        <Typography variant="small" color={"text.muted"}>
                            {bytesInGB(subscription.storage, 2)}{" "}
                            {t("storage_unit.gb")}
                        </Typography>
                    </Box>
                    <IconButton onClick={closeModal} color="secondary">
                        <Close />
                    </IconButton>
                </SpaceBetweenFlex>
            </Box>

            <Box px={1.5}>
                <Typography color={"text.muted"} fontWeight={"bold"}>
                    <Trans
                        i18nKey="CURRENT_USAGE"
                        values={{
                            usage: `${bytesInGB(usage, 2)} ${t("storage_unit.gb")}`,
                        }}
                    />
                </Typography>
            </Box>

            <Box>
                <Stack
                    spacing={3}
                    border={(theme) => `1px solid ${theme.palette.divider}`}
                    p={1.5}
                    borderRadius={(theme) => `${theme.shape.borderRadius}px`}
                >
                    <Box>
                        <PeriodToggler
                            planPeriod={planPeriod}
                            togglePeriod={togglePeriod}
                        />
                        <Typography variant="small" mt={0.5} color="text.muted">
                            {t("TWO_MONTHS_FREE")}
                        </Typography>
                    </Box>
                    {children}
                </Stack>

                <Box py={1} px={1.5}>
                    <Typography color={"text.muted"}>
                        {!isSubscriptionCancelled(subscription)
                            ? t("subscription_status_renewal_active", {
                                  date: subscription.expiryTime,
                              })
                            : t("subscription_status_renewal_cancelled", {
                                  date: subscription.expiryTime,
                              })}
                    </Typography>
                    {hasAddOnBonus(bonusData) && (
                        <BFAddOnRow
                            bonusData={bonusData}
                            closeModal={closeModal}
                        />
                    )}
                </Box>
            </Box>

            <ManageSubscription
                subscription={subscription}
                bonusData={bonusData}
                closeModal={closeModal}
                setLoading={setLoading}
            />
        </>
    );
}

function PeriodToggler({ planPeriod, togglePeriod }) {
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

function BFAddOnRow({ bonusData, closeModal }) {
    return (
        <>
            {bonusData.storageBonuses.map((bonus) => {
                if (bonus.type.startsWith("ADD_ON")) {
                    return (
                        <AddOnRowContainer key={bonus.id} onClick={closeModal}>
                            <Box>
                                <Typography color="text.muted">
                                    <Trans
                                        i18nKey={"add_on_valid_till"}
                                        values={{
                                            storage: formattedStorageByteSize(
                                                bonus.storage,
                                            ),
                                            date: bonus.validTill,
                                        }}
                                    />
                                </Typography>
                            </Box>
                        </AddOnRowContainer>
                    );
                }
                return null;
            })}
        </>
    );
}

const AddOnRowContainer = styled(SpaceBetweenFlex)(({ theme }) => ({
    // gap: theme.spacing(1.5),
    padding: theme.spacing(1, 0),
    cursor: "pointer",
    "&:hover .endIcon": {
        backgroundColor: "rgba(255,255,255,0.08)",
    },
}));

interface ManageSubscriptionProps {
    subscription: Subscription;
    bonusData?: BonusData;
    closeModal: () => void;
    setLoading: SetLoading;
}

function ManageSubscription({
    subscription,
    bonusData,
    closeModal,
    setLoading,
}: ManageSubscriptionProps) {
    const appContext = useContext(AppContext);
    const openFamilyPortal = () =>
        manageFamilyMethod(appContext.setDialogMessage, setLoading);

    return (
        <Stack spacing={1}>
            {hasStripeSubscription(subscription) && (
                <StripeSubscriptionOptions
                    subscription={subscription}
                    bonusData={bonusData}
                    closeModal={closeModal}
                    setLoading={setLoading}
                />
            )}
            <ManageSubscriptionButton
                color="secondary"
                onClick={openFamilyPortal}
            >
                {t("MANAGE_FAMILY_PORTAL")}
            </ManageSubscriptionButton>
        </Stack>
    );
}

function StripeSubscriptionOptions({
    subscription,
    bonusData,
    setLoading,
    closeModal,
}: ManageSubscriptionProps) {
    const appContext = useContext(AppContext);

    const confirmReactivation = () =>
        appContext.setDialogMessage({
            title: t("REACTIVATE_SUBSCRIPTION"),
            content: t("REACTIVATE_SUBSCRIPTION_MESSAGE", {
                date: subscription.expiryTime,
            }),
            proceed: {
                text: t("REACTIVATE_SUBSCRIPTION"),
                action: activateSubscription.bind(
                    null,
                    appContext.setDialogMessage,
                    closeModal,
                    setLoading,
                ),
                variant: "accent",
            },
            close: {
                text: t("cancel"),
            },
        });
    const confirmCancel = () =>
        appContext.setDialogMessage({
            title: t("CANCEL_SUBSCRIPTION"),
            content: hasAddOnBonus(bonusData) ? (
                <Trans i18nKey={"CANCEL_SUBSCRIPTION_WITH_ADDON_MESSAGE"} />
            ) : (
                <Trans i18nKey={"CANCEL_SUBSCRIPTION_MESSAGE"} />
            ),
            proceed: {
                text: t("CANCEL_SUBSCRIPTION"),
                action: cancelSubscription.bind(
                    null,
                    appContext.setDialogMessage,
                    closeModal,
                    setLoading,
                ),
                variant: "critical",
            },
            close: {
                text: t("NEVERMIND"),
            },
        });
    const openManagementPortal = updatePaymentMethod.bind(
        null,
        appContext.setDialogMessage,
        setLoading,
    );
    return (
        <>
            {isSubscriptionCancelled(subscription) ? (
                <ManageSubscriptionButton
                    color="secondary"
                    onClick={confirmReactivation}
                >
                    {t("REACTIVATE_SUBSCRIPTION")}
                </ManageSubscriptionButton>
            ) : (
                <ManageSubscriptionButton
                    color="secondary"
                    onClick={confirmCancel}
                >
                    {t("CANCEL_SUBSCRIPTION")}
                </ManageSubscriptionButton>
            )}
            <ManageSubscriptionButton
                color="secondary"
                onClick={openManagementPortal}
            >
                {t("MANAGEMENT_PORTAL")}
            </ManageSubscriptionButton>
        </>
    );
}

const ManageSubscriptionButton = ({ children, ...props }: ButtonProps) => (
    <Button size="large" endIcon={<ChevronRight />} {...props}>
        <FluidContainer>{children}</FluidContainer>
    </Button>
);
