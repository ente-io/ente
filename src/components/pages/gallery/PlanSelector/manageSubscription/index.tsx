import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { Subscription } from 'types/billing';
import {
    activateSubscription,
    cancelSubscription,
    updatePaymentMethod,
    manageFamilyMethod,
    hasPaidSubscription,
    hasStripeSubscription,
    isSubscriptionCancelled,
} from 'utils/billing';
import constants from 'utils/strings/constants';
import ManageSubscriptionButton from './button';
interface Iprops {
    subscription: Subscription;
    closeModal: () => void;
    setLoading: (value: boolean) => void;
}

export function ManageSubscription({
    subscription,
    closeModal,
    setLoading,
}: Iprops) {
    return (
        <>
            {hasPaidSubscription(subscription) ? (
                <PaidSubscriptionOptions
                    subscription={subscription}
                    setLoading={setLoading}
                    closeModal={closeModal}
                />
            ) : (
                <FreeSubscriptionOptions
                    subscription={subscription}
                    closeModal={closeModal}
                />
            )}
        </>
    );
}

function StripeSubscriptionOptions({
    subscription,
    setLoading,
    closeModal,
}: Iprops) {
    const appContext = useContext(AppContext);

    const confirmActivation = () =>
        appContext.setDialogMessage({
            title: constants.CONFIRM_ACTIVATE_SUBSCRIPTION,
            content: constants.ACTIVATE_SUBSCRIPTION_MESSAGE(
                subscription.expiryTime
            ),
            proceed: {
                text: constants.ACTIVATE_SUBSCRIPTION,
                action: activateSubscription.bind(
                    null,
                    appContext.setDialogMessage,
                    closeModal,
                    setLoading
                ),
                variant: 'accent',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    const confirmCancel = () =>
        appContext.setDialogMessage({
            title: constants.CANCEL_SUBSCRIPTION,
            content: constants.CANCEL_SUBSCRIPTION_MESSAGE(),
            proceed: {
                text: constants.CANCEL_SUBSCRIPTION,
                action: cancelSubscription.bind(
                    null,
                    appContext.setDialogMessage,
                    closeModal,
                    setLoading
                ),
                variant: 'danger',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    const openManagementPortal = updatePaymentMethod.bind(
        null,
        appContext.setDialogMessage,
        setLoading
    );
    return (
        <>
            {isSubscriptionCancelled(subscription) ? (
                <ManageSubscriptionButton
                    color="accent"
                    onClick={confirmActivation}>
                    {constants.ACTIVATE_SUBSCRIPTION}
                </ManageSubscriptionButton>
            ) : (
                <ManageSubscriptionButton
                    color="danger"
                    onClick={confirmCancel}>
                    {constants.CANCEL_SUBSCRIPTION}
                </ManageSubscriptionButton>
            )}
            <ManageSubscriptionButton
                color="accent"
                onClick={openManagementPortal}>
                {constants.MANAGEMENT_PORTAL}
            </ManageSubscriptionButton>
        </>
    );
}

function PaidSubscriptionOptions({
    subscription,
    setLoading,
    closeModal,
}: Iprops) {
    const appContext = useContext(AppContext);
    const openFamilyPortal = () =>
        manageFamilyMethod(appContext.setDialogMessage, setLoading);

    return (
        <>
            {hasStripeSubscription(subscription) && (
                <StripeSubscriptionOptions
                    subscription={subscription}
                    closeModal={closeModal}
                    setLoading={setLoading}
                />
            )}
            <ManageSubscriptionButton color="accent" onClick={openFamilyPortal}>
                {constants.MANAGE_FAMILY_PORTAL}
            </ManageSubscriptionButton>
        </>
    );
}

function FreeSubscriptionOptions({ closeModal }: Omit<Iprops, 'setLoading'>) {
    return (
        <ManageSubscriptionButton color="accent" onClick={closeModal}>
            {constants.SKIP_SUBSCRIPTION_PURCHASE}
        </ManageSubscriptionButton>
    );
}
