import log from "@/next/log";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { SUPPORT_EMAIL } from "@ente/shared/constants/urls";
import Close from "@mui/icons-material/Close";
import { IconButton, Link, Stack } from "@mui/material";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import { PLAN_PERIOD } from "constants/gallery";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";
import billingService, { type PlansResponse } from "services/billingService";
import { Plan } from "types/billing";
import { SetLoading } from "types/gallery";
import {
    getLocalUserSubscription,
    hasAddOnBonus,
    hasMobileSubscription,
    hasPaidSubscription,
    hasStripeSubscription,
    isOnFreePlan,
    isSubscriptionActive,
    isSubscriptionCancelled,
    isUserSubscribedPlan,
    planForSubscription,
    updateSubscription,
} from "utils/billing";
import { bytesInGB } from "utils/units";
import { getLocalUserDetails } from "utils/user";
import { getTotalFamilyUsage, isPartOfFamily } from "utils/user/family";
import { ManageSubscription } from "./manageSubscription";
import { PeriodToggler } from "./periodToggler";
import Plans from "./plans";
import { BFAddOnRow } from "./plans/BfAddOnRow";

interface Props {
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelectorCard(props: Props) {
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
        if (
            !hasPaidSubscription(subscription) &&
            !isSubscriptionCancelled(subscription)
        ) {
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
        } else if (hasStripeSubscription(subscription)) {
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
                close: { text: t("CANCEL") },
            });
        } else if (hasMobileSubscription(subscription)) {
            appContext.setDialogMessage({
                title: t("CANCEL_SUBSCRIPTION_ON_MOBILE"),
                content: t("CANCEL_SUBSCRIPTION_ON_MOBILE_MESSAGE"),
                close: { variant: "secondary" },
            });
        } else {
            appContext.setDialogMessage({
                title: t("MANAGE_PLAN"),
                content: (
                    <Trans
                        i18nKey={"MAIL_TO_MANAGE_SUBSCRIPTION"}
                        components={{
                            a: <Link href={`mailto:${SUPPORT_EMAIL}`} />,
                        }}
                        values={{ emailID: SUPPORT_EMAIL }}
                    />
                ),
                close: { variant: "secondary" },
            });
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

export default PlanSelectorCard;

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
                            ? t("RENEWAL_ACTIVE_SUBSCRIPTION_STATUS", {
                                  date: subscription.expiryTime,
                              })
                            : t("RENEWAL_CANCELLED_SUBSCRIPTION_STATUS", {
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
