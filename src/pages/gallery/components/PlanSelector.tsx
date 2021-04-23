import React, { useEffect, useState } from 'react';
import { Form, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import billingService, { Plan, Subscription } from 'services/billingService';
import {
    convertBytesToGBs,
    getPlans,
    getUserSubscription,
    isUserSubscribedPlan,
    isSubscriptionCancelled,
    updatePaymentMethod,
    SetConfirmAction,
    SetDialogMessage,
    SetLoading,
    updateSubscription,
    activateSubscription,
    cancelSubscription,
    hasStripeSubscription,
    hasPaidSubscription,
    isOnFreePlan,
} from 'utils/billingUtil';
import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import { LoadingOverlay } from './CollectionSelector';
import EnteSpinner from 'components/EnteSpinner';
import { DeadCenter } from '..';
import LinkButton from './LinkButton';

export const PlanIcon = styled.div<{ selected: boolean }>`
    padding-top: 20px;
    border-radius: 10%;
    height: 192px;
    width: 250px;
    border: 2px solid #868686;
    margin: 10px;
    text-align: center;
    font-size: 20px;
    cursor: ${(props) => (props.selected ? 'not-allowed' : 'pointer')};
    border-color: ${(props) => props.selected && '#56e066'};
`;

interface Props {
    modalView: boolean;
    closeModal: any;
    setDialogMessage: SetDialogMessage;
    setConfirmAction: SetConfirmAction;
    setLoading: SetLoading;
}
enum PLAN_PERIOD {
    MONTH = 'month',
    YEAR = 'year',
}
function PlanSelector(props: Props) {
    const subscription: Subscription = getUserSubscription();
    const plans = getPlans();
    const [planPeriod, setPlanPeriod] = useState<PLAN_PERIOD>(PLAN_PERIOD.YEAR);
    const togglePeriod = () => {
        setPlanPeriod((prevPeriod) =>
            prevPeriod == PLAN_PERIOD.MONTH
                ? PLAN_PERIOD.YEAR
                : PLAN_PERIOD.MONTH
        );
    };
    useEffect(() => {
        if (!plans) {
            const main = async () => {
                props.setLoading(true);
                await billingService.updatePlans();
                props.setLoading(false);
            };
            main();
        }
    });

    async function onPlanSelect(plan: Plan) {
        if (
            hasPaidSubscription(subscription) &&
            !hasStripeSubscription(subscription) &&
            !isSubscriptionCancelled(subscription)
        ) {
            props.setDialogMessage({
                title: constants.ERROR,
                content: constants.CANCEL_SUBSCRIPTION_ON_MOBILE,
                close: { variant: 'danger' },
            });
        } else if (hasStripeSubscription(subscription)) {
            props.setConfirmAction({
                action: CONFIRM_ACTION.UPDATE_SUBSCRIPTION,
                callback: updateSubscription.bind(
                    null,
                    plan,
                    props.setDialogMessage,
                    props.setLoading,
                    props.setConfirmAction,
                    props.closeModal
                ),
            });
        } else {
            try {
                props.setLoading(true);
                await billingService.buyPaidSubscription(plan.stripeID);
            } catch (e) {
                props.setDialogMessage({
                    title: constants.ERROR,
                    content: constants.SUBSCRIPTION_PURCHASE_FAILED,
                    close: { variant: 'danger' },
                });
            } finally {
                props.setLoading(false);
            }
        }
    }

    const PlanIcons: JSX.Element[] = plans
        ?.filter((plan) => plan.period == planPeriod)
        ?.map((plan) => (
            <PlanIcon
                key={plan.stripeID}
                onClick={async () =>
                    !isUserSubscribedPlan(plan, subscription) &&
                    (await onPlanSelect(plan))
                }
                className='subscription-plan-selector'
                selected={isUserSubscribedPlan(plan, subscription)}
            >
                <div>
                    <span
                        style={{
                            color: '#ECECEC',
                            fontWeight: 900,
                            fontSize: '72px',
                        }}
                    >
                        {convertBytesToGBs(plan.storage, 0)}
                    </span>
                    <span
                        style={{
                            color: '#858585',
                            fontSize: '24px',
                            fontWeight: 900,
                        }}
                    >
                        {' '}
                        GB
                    </span>
                </div>
                <div
                    className={`bold-text`} style={{ color: "#aaa" }}
                >{`${plan.price} / ${plan.period}`}</div>
            </PlanIcon>
        ));
    return (
        <Modal
            show={props.modalView}
            onHide={props.closeModal}
            dialogClassName="modal-90w"
            centered
            backdrop={hasPaidSubscription(subscription) ? 'true' : `static`}
        >
            <Modal.Header closeButton>
                <Modal.Title
                    style={{
                        marginLeft: '12px',
                        width: '100%',
                        textAlign: 'center',
                    }}
                >
                    <span>
                        {hasPaidSubscription(subscription)
                            ? constants.MANAGE_PLAN
                            : constants.CHOOSE_PLAN}
                    </span>
                </Modal.Title>
            </Modal.Header>
            <Modal.Body style={{ marginTop: '20px' }}>
                <DeadCenter>
                    <div style={{ display: 'flex' }}>
                        <span className={`bold-text`} style={{ fontSize: '20px' }}>{constants.YEARLY}</span>

                        <Form.Switch
                            checked={planPeriod == PLAN_PERIOD.MONTH}
                            id={`plan-period-toggler`}
                            style={{ marginLeft: '15px', marginTop: '-4px' }}
                            className={`custom-switch-md`}
                            onChange={togglePeriod}
                        />
                        <span className={`bold-text`} style={{ fontSize: '20px' }}>{constants.MONTHLY}</span>
                    </div>
                </DeadCenter>
                <div
                    style={{
                        display: 'flex',
                        justifyContent: 'space-around',
                        flexWrap: 'wrap',
                        minHeight: '212px',
                        marginTop: '24px',
                        marginBottom: '36px',
                    }}
                >
                    {plans && PlanIcons}
                </div>
                <DeadCenter style={{ marginBottom: '30px' }}>
                    {hasStripeSubscription(subscription) ? (
                        <>
                            {isSubscriptionCancelled(subscription) ? (
                                <LinkButton
                                    variant="success"
                                    onClick={() =>
                                        props.setConfirmAction({
                                            action:
                                                CONFIRM_ACTION.ACTIVATE_SUBSCRIPTION,
                                            callback: activateSubscription.bind(
                                                null,
                                                props.setDialogMessage,
                                                props.closeModal,
                                                props.setLoading
                                            ),
                                            messageAttribute: {
                                                content: constants.ACTIVATE_SUBSCRIPTION_MESSAGE(
                                                    subscription.expiryTime
                                                ),
                                            },
                                        })
                                    }
                                >
                                    {constants.ACTIVATE_SUBSCRIPTION}
                                </LinkButton>
                            ) : (
                                <LinkButton
                                    variant="danger"
                                    onClick={() =>
                                        props.setConfirmAction({
                                            action:
                                                CONFIRM_ACTION.CANCEL_SUBSCRIPTION,
                                            callback: cancelSubscription.bind(
                                                null,
                                                props.setDialogMessage,
                                                props.closeModal,
                                                props.setLoading
                                            ),
                                        })
                                    }
                                >
                                    {constants.CANCEL_SUBSCRIPTION}
                                </LinkButton>
                            )}
                            <LinkButton
                                variant="primary"
                                onClick={(event) =>
                                    updatePaymentMethod(
                                        event,
                                        props.setDialogMessage,
                                        props.setLoading
                                    )
                                }
                                style={{ marginTop: '20px' }}
                            >
                                {constants.MANAGEMENT_PORTAL}
                            </LinkButton>
                        </>
                    ) : (
                        <LinkButton
                            variant="primary"
                            onClick={props.closeModal}
                            style={{ color: 'rgb(121, 121, 121)' }}
                        >
                            {isOnFreePlan(subscription)
                                ? constants.SKIP
                                : constants.CLOSE}
                        </LinkButton>
                    )}
                </DeadCenter>
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
