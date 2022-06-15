import { DeadCenter } from 'pages/gallery';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import {
    activateSubscription,
    cancelSubscription,
    updatePaymentMethod,
    manageFamilyMethod,
    hasPaidSubscription,
    hasStripeSubscription,
    isOnFreePlan,
    isSubscriptionCancelled,
} from 'utils/billing';
import constants from 'utils/strings/constants';
import LinkButton from '../LinkButton';
export function ManageSubscription({ subscription, ...props }) {
    const appContext = useContext(AppContext);
    return (
        <DeadCenter>
            {hasPaidSubscription(subscription) ? (
                <>
                    {hasStripeSubscription(subscription) && (
                        <>
                            {isSubscriptionCancelled(subscription) ? (
                                <LinkButton
                                    color="accent"
                                    onClick={() =>
                                        appContext.setDialogMessage({
                                            title: constants.CONFIRM_ACTIVATE_SUBSCRIPTION,
                                            content:
                                                constants.ACTIVATE_SUBSCRIPTION_MESSAGE(
                                                    subscription.expiryTime
                                                ),
                                            proceed: {
                                                text: constants.ACTIVATE_SUBSCRIPTION,
                                                action: activateSubscription.bind(
                                                    null,
                                                    appContext.setDialogMessage,
                                                    props.closeModal,
                                                    props.setLoading
                                                ),
                                                variant: 'accent',
                                            },
                                            close: {
                                                text: constants.CANCEL,
                                            },
                                        })
                                    }>
                                    {constants.ACTIVATE_SUBSCRIPTION}
                                </LinkButton>
                            ) : (
                                <LinkButton
                                    color="danger"
                                    onClick={() =>
                                        appContext.setDialogMessage({
                                            title: constants.CONFIRM_CANCEL_SUBSCRIPTION,
                                            content:
                                                constants.CANCEL_SUBSCRIPTION_MESSAGE(),
                                            proceed: {
                                                text: constants.CANCEL_SUBSCRIPTION,
                                                action: cancelSubscription.bind(
                                                    null,
                                                    appContext.setDialogMessage,
                                                    props.closeModal,
                                                    props.setLoading
                                                ),
                                                variant: 'danger',
                                            },
                                            close: {
                                                text: constants.CANCEL,
                                            },
                                        })
                                    }>
                                    {constants.CANCEL_SUBSCRIPTION}
                                </LinkButton>
                            )}
                            <LinkButton
                                onClick={updatePaymentMethod.bind(
                                    null,
                                    appContext.setDialogMessage,
                                    props.setLoading
                                )}
                                sx={{
                                    mt: 1,
                                }}>
                                {constants.MANAGEMENT_PORTAL}
                            </LinkButton>
                        </>
                    )}
                    <LinkButton
                        onClick={manageFamilyMethod.bind(
                            null,
                            appContext.setDialogMessage,
                            props.setLoading
                        )}
                        sx={{
                            mt: 1,
                        }}>
                        {constants.MANAGE_FAMILY_PORTAL}
                    </LinkButton>
                </>
            ) : (
                <LinkButton
                    onClick={props.closeModal}
                    style={{
                        color: 'rgb(121, 121, 121)',
                        marginTop: '20px',
                    }}>
                    {isOnFreePlan(subscription)
                        ? constants.SKIP
                        : constants.CLOSE}
                </LinkButton>
            )}
        </DeadCenter>
    );
}
