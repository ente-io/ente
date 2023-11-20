import { Stack } from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import { Subscription } from 'types/billing';
import { SetLoading } from 'types/gallery';
import {
    activateSubscription,
    cancelSubscription,
    updatePaymentMethod,
    manageFamilyMethod,
    hasStripeSubscription,
    isSubscriptionCancelled,
    hasAddOnBonus,
} from 'utils/billing';
import ManageSubscriptionButton from './button';
import { BonusData } from 'types/user';

interface Iprops {
    subscription: Subscription;
    bonusData?: BonusData;
    closeModal: () => void;
    setLoading: SetLoading;
}

export function ManageSubscription({
    subscription,
    bonusData,
    closeModal,
    setLoading,
}: Iprops) {
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
                onClick={openFamilyPortal}>
                {t('MANAGE_FAMILY_PORTAL')}
            </ManageSubscriptionButton>
        </Stack>
    );
}

function StripeSubscriptionOptions({
    subscription,
    bonusData,
    setLoading,
    closeModal,
}: Iprops) {
    const appContext = useContext(AppContext);

    const confirmReactivation = () =>
        appContext.setDialogMessage({
            title: t('REACTIVATE_SUBSCRIPTION'),
            content: t('REACTIVATE_SUBSCRIPTION_MESSAGE', {
                date: subscription.expiryTime,
            }),
            proceed: {
                text: t('REACTIVATE_SUBSCRIPTION'),
                action: activateSubscription.bind(
                    null,
                    appContext.setDialogMessage,
                    closeModal,
                    setLoading
                ),
                variant: 'accent',
            },
            close: {
                text: t('CANCEL'),
            },
        });
    const confirmCancel = () =>
        appContext.setDialogMessage({
            title: t('CANCEL_SUBSCRIPTION'),
            content: hasAddOnBonus(bonusData) ? (
                <Trans i18nKey={'CANCEL_SUBSCRIPTION_WITH_ADDON_MESSAGE'} />
            ) : (
                <Trans i18nKey={'CANCEL_SUBSCRIPTION_MESSAGE'} />
            ),
            proceed: {
                text: t('CANCEL_SUBSCRIPTION'),
                action: cancelSubscription.bind(
                    null,
                    appContext.setDialogMessage,
                    closeModal,
                    setLoading
                ),
                variant: 'critical',
            },
            close: {
                text: t('NEVERMIND'),
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
                    color="secondary"
                    onClick={confirmReactivation}>
                    {t('REACTIVATE_SUBSCRIPTION')}
                </ManageSubscriptionButton>
            ) : (
                <ManageSubscriptionButton
                    color="secondary"
                    onClick={confirmCancel}>
                    {t('CANCEL_SUBSCRIPTION')}
                </ManageSubscriptionButton>
            )}
            <ManageSubscriptionButton
                color="secondary"
                onClick={openManagementPortal}>
                {t('MANAGEMENT_PORTAL')}
            </ManageSubscriptionButton>
        </>
    );
}
