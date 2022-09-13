import React, { useContext, useEffect, useMemo, useState } from 'react';
import constants from 'utils/strings/constants';
import { Plan } from 'types/billing';
import {
    isUserSubscribedPlan,
    isSubscriptionCancelled,
    updateSubscription,
    hasStripeSubscription,
    isOnFreePlan,
    planForSubscription,
    hasMobileSubscription,
    getLocalUserSubscription,
    hasPaidSubscription,
    getTotalFamilyUsage,
    isPartOfFamily,
} from 'utils/billing';
import { reverseString } from 'utils/common';
import { GalleryContext } from 'pages/gallery';
import billingService from 'services/billingService';
import { SetLoading } from 'types/gallery';
import { logError } from 'utils/sentry';
import { AppContext } from 'pages/_app';
import { Stack } from '@mui/material';
import { useLocalState } from 'hooks/useLocalState';
import { LS_KEYS } from 'utils/storage/localStorage';
import { getLocalUserDetails } from 'utils/user';
import { PLAN_PERIOD } from 'constants/gallery';
import FreeSubscriptionPlanSelectorCard from './free';
import PaidSubscriptionPlanSelectorCard from './paid';

interface Props {
    closeModal: any;
    setLoading: SetLoading;
}

function PlanSelectorCard(props: Props) {
    const subscription = useMemo(() => getLocalUserSubscription(), []);
    const [plans, setPlans] = useLocalState<Plan[]>(LS_KEYS.PLANS);

    const [planPeriod, setPlanPeriod] = useState<PLAN_PERIOD>(
        subscription?.period || PLAN_PERIOD.MONTH
    );
    const galleryContext = useContext(GalleryContext);
    const appContext = useContext(AppContext);

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
                : PLAN_PERIOD.MONTH
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
                let plans = await billingService.getPlans();

                const planNotListed =
                    plans.filter((plan) =>
                        isUserSubscribedPlan(plan, subscription)
                    ).length === 0;
                if (
                    subscription &&
                    !isOnFreePlan(subscription) &&
                    planNotListed
                ) {
                    plans = [planForSubscription(subscription), ...plans];
                }
                setPlans(plans);
            } catch (e) {
                logError(e, 'plan selector modal open failed');
                props.closeModal();
                appContext.setDialogMessage({
                    title: constants.OPEN_PLAN_SELECTOR_MODAL_FAILED,
                    content: constants.UNKNOWN_ERROR,
                    close: { text: constants.CLOSE, variant: 'secondary' },
                    proceed: {
                        text: constants.REOPEN_PLAN_SELECTOR_MODAL,
                        variant: 'accent',
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
            hasMobileSubscription(subscription) &&
            !isSubscriptionCancelled(subscription)
        ) {
            appContext.setDialogMessage({
                title: constants.ERROR,
                content: constants.CANCEL_SUBSCRIPTION_ON_MOBILE,
                close: { variant: 'danger' },
            });
        } else if (
            hasPaidSubscription(subscription) &&
            !isSubscriptionCancelled(subscription)
        ) {
            appContext.setDialogMessage({
                title: constants.MANAGE_PLAN,
                content: constants.MANAGE_NOT_SUPPORTED_MESSAGE(
                    subscription.paymentProvider
                ),
                close: { variant: 'secondary' },
            });
        } else if (hasStripeSubscription(subscription)) {
            appContext.setDialogMessage({
                title: `${constants.CONFIRM} ${reverseString(
                    constants.UPDATE_SUBSCRIPTION
                )}`,
                content: constants.UPDATE_SUBSCRIPTION_MESSAGE,
                proceed: {
                    text: constants.UPDATE_SUBSCRIPTION,
                    action: updateSubscription.bind(
                        null,
                        plan,
                        appContext.setDialogMessage,
                        props.setLoading,
                        props.closeModal
                    ),
                    variant: 'accent',
                },
                close: { text: constants.CANCEL },
            });
        } else {
            try {
                props.setLoading(true);
                await billingService.buySubscription(plan.stripeID);
            } catch (e) {
                props.setLoading(false);
                appContext.setDialogMessage({
                    title: constants.ERROR,
                    content: constants.SUBSCRIPTION_PURCHASE_FAILED,
                    close: { variant: 'danger' },
                });
            }
        }
    }

    return (
        <>
            <Stack spacing={3} p={1.5}>
                {hasPaidSubscription(subscription) ? (
                    <PaidSubscriptionPlanSelectorCard
                        plans={plans}
                        subscription={subscription}
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
                        closeModal={props.closeModal}
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
