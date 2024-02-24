import { SUPPORT_EMAIL } from "@ente/shared/constants/urls";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import { logError } from "@ente/shared/sentry";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import { Link, Stack } from "@mui/material";
import { PLAN_PERIOD } from "constants/gallery";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";
import billingService from "services/billingService";
import { Plan } from "types/billing";
import { SetLoading } from "types/gallery";
import {
    getLocalUserSubscription,
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
import { reverseString } from "utils/common";
import { getLocalUserDetails } from "utils/user";
import { getTotalFamilyUsage, isPartOfFamily } from "utils/user/family";
import FreeSubscriptionPlanSelectorCard from "./free";
import PaidSubscriptionPlanSelectorCard from "./paid";

interface Props {
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelectorCard(props: Props) {
    const subscription = useMemo(() => getLocalUserSubscription(), []);
    const [plans, setPlans] = useLocalState<Plan[]>(LS_KEYS.PLANS);

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
                const plans = await billingService.getPlans();
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
                setPlans(plans);
            } catch (e) {
                logError(e, "plan selector modal open failed");
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
            !hasPaidSubscription(subscription) ||
            isSubscriptionCancelled(subscription)
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
                title: `${t("CONFIRM")} ${reverseString(
                    t("UPDATE_SUBSCRIPTION"),
                )}`,
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

    return (
        <>
            <Stack spacing={3} p={1.5}>
                {hasPaidSubscription(subscription) ? (
                    <PaidSubscriptionPlanSelectorCard
                        plans={plans}
                        subscription={subscription}
                        bonusData={bonusData}
                        closeModal={props.closeModal}
                        planPeriod={planPeriod}
                        togglePeriod={togglePeriod}
                        onPlanSelect={onPlanSelect}
                        setLoading={props.setLoading}
                        usage={usage}
                    />
                ) : (
                    <FreeSubscriptionPlanSelectorCard
                        plans={plans}
                        subscription={subscription}
                        bonusData={bonusData}
                        closeModal={props.closeModal}
                        setLoading={props.setLoading}
                        planPeriod={planPeriod}
                        togglePeriod={togglePeriod}
                        onPlanSelect={onPlanSelect}
                    />
                )}
            </Stack>
        </>
    );
}

export default PlanSelectorCard;
