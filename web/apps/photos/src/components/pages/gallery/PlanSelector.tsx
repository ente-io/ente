import {
    errorDialogAttributes,
    genericRetriableErrorDialogAttributes,
} from "@/base/components/utils/dialog";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import log from "@/base/log";
import { useUserDetailsSnapshot } from "@/new/photos/components/utils/use-snapshot";
import { useWrapAsyncOperation } from "@/new/photos/components/utils/use-wrap-async";
import type {
    Bonus,
    Plan,
    PlanPeriod,
    PlansData,
    Subscription,
} from "@/new/photos/services/user-details";
import {
    activateStripeSubscription,
    cancelStripeSubscription,
    getFamilyPortalRedirectURL,
    getPlansData,
    isSubscriptionActive,
    isSubscriptionActivePaid,
    isSubscriptionCancelled,
    isSubscriptionForPlan,
    isSubscriptionFree,
    isSubscriptionStripe,
    planUsage,
    redirectToCustomerPortal,
    redirectToPaymentsApp,
    userDetailsAddOnBonuses,
} from "@/new/photos/services/user-details";
import { AppContext, useAppContext } from "@/new/photos/types/context";
import { bytesInGB, formattedStorageByteSize } from "@/new/photos/utils/units";
import { openURL } from "@/new/photos/utils/web";
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
import { t } from "i18next";
import React, { useCallback, useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { SetLoading } from "types/gallery";

type PlanSelectorProps = ModalVisibilityProps & {
    setLoading: SetLoading;
};

const PlanSelector: React.FC<PlanSelectorProps> = ({
    open,
    onClose,
    setLoading,
}: PlanSelectorProps) => {
    const fullScreen = useMediaQuery(useTheme().breakpoints.down("sm"));

    if (!open) {
        return <></>;
    }

    return (
        <Dialog
            {...{ open, onClose, fullScreen }}
            PaperProps={{
                sx: (theme) => ({
                    width: { sm: "391px" },
                    p: 1,
                    [theme.breakpoints.down(360)]: { p: 0 },
                }),
            }}
        >
            <PlanSelectorCard {...{ onClose, setLoading }} />
        </Dialog>
    );
};

export default PlanSelector;

interface PlanSelectorCardProps {
    onClose: () => void;
    setLoading: SetLoading;
}

const PlanSelectorCard: React.FC<PlanSelectorCardProps> = ({
    onClose,
    setLoading,
}) => {
    const { showMiniDialog } = useContext(AppContext);

    const userDetails = useUserDetailsSnapshot();

    const [plansData, setPlansData] = useState<PlansData | undefined>();
    const [planPeriod, setPlanPeriod] = useState<PlanPeriod | undefined>(
        userDetails?.subscription?.period ?? "month",
    );

    const usage = userDetails ? planUsage(userDetails) : 0;
    const subscription = userDetails?.subscription;
    const addOnBonuses = userDetails
        ? userDetailsAddOnBonuses(userDetails)
        : [];

    const togglePeriod = useCallback(
        () => setPlanPeriod((prev) => (prev == "month" ? "year" : "month")),
        [],
    );

    useEffect(() => {
        const main = async () => {
            try {
                setLoading(true);
                const plansData = await getPlansData();
                const { plans } = plansData;
                if (subscription && isSubscriptionActive(subscription)) {
                    const activePlan = plans.find((plan) =>
                        isSubscriptionForPlan(subscription, plan),
                    );
                    if (!isSubscriptionFree(subscription) && !activePlan) {
                        plans.push({
                            id: subscription.productID,
                            storage: subscription.storage,
                            price: subscription.price,
                            period: subscription.period,
                            stripeID: subscription.productID,
                            iosID: subscription.productID,
                            androidID: subscription.productID,
                        });
                    }
                }
                setPlansData(plansData);
            } catch (e) {
                log.error("Failed to get plans", e);
                onClose();
                showMiniDialog(genericRetriableErrorDialogAttributes());
            } finally {
                setLoading(false);
            }
        };
        main();
    }, []);

    const handlePlanSelect = async (plan: Plan) => {
        switch (planSelectionOutcome(subscription)) {
            case "buyPlan":
                try {
                    setLoading(true);
                    await redirectToPaymentsApp(plan.stripeID, "buy");
                } catch (e) {
                    setLoading(false);
                    showMiniDialog(
                        errorDialogAttributes(
                            t("SUBSCRIPTION_PURCHASE_FAILED"),
                        ),
                    );
                }
                break;

            case "updateSubscriptionToPlan":
                showMiniDialog({
                    title: t("update_subscription_title"),
                    message: t("UPDATE_SUBSCRIPTION_MESSAGE"),
                    continue: {
                        text: t("UPDATE_SUBSCRIPTION"),
                        action: () =>
                            redirectToPaymentsApp(plan.stripeID, "update"),
                    },
                });
                break;

            case "cancelOnMobile":
                showMiniDialog({
                    title: t("CANCEL_SUBSCRIPTION_ON_MOBILE"),
                    message: t("CANCEL_SUBSCRIPTION_ON_MOBILE_MESSAGE"),
                    continue: {},
                    cancel: false,
                });
                break;

            case "contactSupport":
                showMiniDialog({
                    title: t("MANAGE_PLAN"),
                    message: (
                        <Trans
                            i18nKey={"MAIL_TO_MANAGE_SUBSCRIPTION"}
                            components={{
                                a: <Link href="mailto:support@ente.io" />,
                            }}
                            values={{ emailID: "support@ente.io" }}
                        />
                    ),
                    continue: {},
                    cancel: false,
                });
                break;
        }
    };

    const commonCardData = {
        subscription,
        addOnBonuses,
        closeModal: onClose,
        planPeriod,
        togglePeriod,
        setLoading,
    };

    const plansList = (
        <Plans
            plansData={plansData}
            planPeriod={planPeriod}
            onPlanSelect={handlePlanSelect}
            subscription={subscription}
            hasAddOnBonus={addOnBonuses.length > 0}
            closeModal={onClose}
        />
    );

    return (
        <Stack spacing={3} p={1.5}>
            {subscription && isSubscriptionActivePaid(subscription) ? (
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
    );
};

/**
 * Return the outcome that should happen when the user selects a paid plan on
 * the plan selection screen.
 *
 * @param subscription Their current subscription details.
 */
const planSelectionOutcome = (subscription: Subscription | undefined) => {
    // This shouldn't happen, but we need this case to handle missing types.
    if (!subscription) return "buyPlan";

    // The user is a on a free plan and can buy the plan they selected.
    if (subscription.productID == "free") return "buyPlan";

    // Their existing subscription has expired. They can buy a new plan.
    if (subscription.expiryTime < Date.now() * 1000) return "buyPlan";

    // -- The user already has an active subscription to a paid plan.

    // Using Stripe.
    if (subscription.paymentProvider == "stripe") {
        // Update their existing subscription to the new plan.
        return "updateSubscriptionToPlan";
    }

    // Using one of the mobile app stores.
    if (
        subscription.paymentProvider == "appstore" ||
        subscription.paymentProvider == "playstore"
    ) {
        // They need to cancel first on the mobile app stores.
        return "cancelOnMobile";
    }

    // Some other bespoke case. They should contact support.
    return "contactSupport";
};

function FreeSubscriptionPlanSelectorCard({
    children,
    subscription,
    addOnBonuses,
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
                    {subscription && addOnBonuses.length > 0 && (
                        <>
                            <AddOnBonusRows addOnBonuses={addOnBonuses} />
                            <ManageSubscription
                                subscription={subscription}
                                hasAddOnBonus={true}
                                closeModal={closeModal}
                                setLoading={setLoading}
                            />
                        </>
                    )}
                </Stack>
            </Box>
        </>
    );
}

function PaidSubscriptionPlanSelectorCard({
    children,
    subscription,
    addOnBonuses,
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
                    {addOnBonuses.length > 0 && (
                        <AddOnBonusRows addOnBonuses={addOnBonuses} />
                    )}
                </Box>
            </Box>

            <ManageSubscription
                subscription={subscription}
                hasAddOnBonus={addOnBonuses.length > 0}
                closeModal={closeModal}
                setLoading={setLoading}
            />
        </>
    );
}

function PeriodToggler({ planPeriod, togglePeriod }) {
    const handleChange = (_, newPlanPeriod: PlanPeriod) => {
        if (newPlanPeriod !== planPeriod) togglePeriod();
    };

    return (
        <ToggleButtonGroup
            value={planPeriod}
            exclusive
            onChange={handleChange}
            color="primary"
        >
            <CustomToggleButton value={"month"}>
                {t("MONTHLY")}
            </CustomToggleButton>
            <CustomToggleButton value={"year"}>
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
    plansData: PlansData | undefined;
    planPeriod: PlanPeriod;
    subscription: Subscription;
    hasAddOnBonus: boolean;
    onPlanSelect: (plan: Plan) => void;
    closeModal: () => void;
}

const Plans = ({
    plansData,
    planPeriod,
    subscription,
    hasAddOnBonus,
    onPlanSelect,
    closeModal,
}: PlansProps) => {
    const { freePlan, plans } = plansData ?? {};
    return (
        <Stack spacing={2}>
            {plans
                ?.filter((plan) => plan.period === planPeriod)
                ?.map((plan) => (
                    <PlanRow
                        disabled={
                            subscription &&
                            isSubscriptionForPlan(subscription, plan)
                        }
                        popular={isPopularPlan(plan)}
                        key={plan.stripeID}
                        plan={plan}
                        subscription={subscription}
                        onPlanSelect={onPlanSelect}
                    />
                ))}
            {!(subscription && isSubscriptionActivePaid(subscription)) &&
                !hasAddOnBonus &&
                freePlan && (
                    <FreePlanRow
                        storage={freePlan.storage}
                        closeModal={closeModal}
                    />
                )}
        </Stack>
    );
};

const isPopularPlan = (plan: Plan) =>
    plan.storage === 100 * 1024 * 1024 * 1024; /* 100 GB */

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
    const handleClick = () => !disabled && onPlanSelect(plan);

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
                    {popular &&
                        !(
                            subscription &&
                            isSubscriptionActivePaid(subscription)
                        ) && <Badge>{t("POPULAR")}</Badge>}
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
                                plan.period === "month"
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

interface AddOnBonusRowsProps {
    addOnBonuses: Bonus[];
}

const AddOnBonusRows: React.FC<AddOnBonusRowsProps> = ({ addOnBonuses }) => (
    <>
        {addOnBonuses.map((bonus, i) => (
            <Typography color="text.muted" key={i} sx={{ pt: 1 }}>
                <Trans
                    i18nKey={"add_on_valid_till"}
                    values={{
                        storage: formattedStorageByteSize(bonus.storage),
                        date: bonus.validTill,
                    }}
                />
            </Typography>
        ))}
    </>
);

interface ManageSubscriptionProps {
    subscription: Subscription;
    hasAddOnBonus: boolean;
    closeModal: () => void;
    setLoading: SetLoading;
}

function ManageSubscription({
    subscription,
    hasAddOnBonus,
    closeModal,
    setLoading,
}: ManageSubscriptionProps) {
    const { onGenericError } = useAppContext();

    const openFamilyPortal = async () => {
        setLoading(true);
        try {
            openURL(await getFamilyPortalRedirectURL());
        } catch (e) {
            onGenericError(e);
        }
        setLoading(false);
    };

    return (
        <Stack spacing={1}>
            {isSubscriptionStripe(subscription) && (
                <StripeSubscriptionOptions
                    onClose={closeModal}
                    subscription={subscription}
                    hasAddOnBonus={hasAddOnBonus}
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

interface StripeSubscriptionOptionsProps {
    onClose: () => void;
    subscription: Subscription;
    hasAddOnBonus: boolean;
}

const StripeSubscriptionOptions: React.FC<StripeSubscriptionOptionsProps> = ({
    onClose,
    subscription,
    hasAddOnBonus,
}) => {
    const { showMiniDialog } = useAppContext();

    const confirmReactivation = () =>
        showMiniDialog({
            title: t("REACTIVATE_SUBSCRIPTION"),
            message: t("REACTIVATE_SUBSCRIPTION_MESSAGE", {
                date: subscription.expiryTime,
            }),
            continue: {
                text: t("REACTIVATE_SUBSCRIPTION"),
                action: async () => {
                    await activateStripeSubscription();
                    onClose();
                    // [Note: Chained MiniDialogs]
                    //
                    // The MiniDialog will automatically close when we the
                    // action promise resolves, so if we want to show another
                    // dialog, schedule it on the next run loop.
                    setTimeout(() => {
                        showMiniDialog({
                            title: t("success"),
                            message: t("SUBSCRIPTION_ACTIVATE_SUCCESS"),
                            continue: { action: onClose },
                            cancel: false,
                        });
                    }, 0);
                },
            },
        });

    const confirmCancel = () =>
        showMiniDialog({
            title: t("CANCEL_SUBSCRIPTION"),
            message: hasAddOnBonus ? (
                <Trans i18nKey={"CANCEL_SUBSCRIPTION_WITH_ADDON_MESSAGE"} />
            ) : (
                <Trans i18nKey={"CANCEL_SUBSCRIPTION_MESSAGE"} />
            ),
            continue: {
                text: t("CANCEL_SUBSCRIPTION"),
                color: "critical",
                action: async () => {
                    await cancelStripeSubscription();
                    onClose();
                    // See: [Note: Chained MiniDialogs]
                    setTimeout(() => {
                        showMiniDialog({
                            message: t("SUBSCRIPTION_CANCEL_SUCCESS"),
                            cancel: t("ok"),
                        });
                    }, 0);
                },
            },
            cancel: t("NEVERMIND"),
        });

    const handleManageClick = useWrapAsyncOperation(redirectToCustomerPortal);

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
                onClick={handleManageClick}
            >
                {t("MANAGEMENT_PORTAL")}
            </ManageSubscriptionButton>
        </>
    );
};

const ManageSubscriptionButton = ({ children, ...props }: ButtonProps) => (
    <Button size="large" endIcon={<ChevronRight />} {...props}>
        <FluidContainer>{children}</FluidContainer>
    </Button>
);
