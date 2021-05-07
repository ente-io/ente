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
    updateSubscription,
    activateSubscription,
    cancelSubscription,
    hasStripeSubscription,
    hasPaidSubscription,
    isOnFreePlan,
} from 'utils/billingUtil';
import { DeadCenter, SetLoading } from '..';
import LinkButton from './LinkButton';
import { reverseString } from 'utils/common';
import { SetDialogMessage } from 'components/MessageDialog';

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
            props.setDialogMessage({
                title: `${constants.CONFIRM} ${reverseString(
                    constants.UPDATE_SUBSCRIPTION
                )}`,
                content: constants.UPDATE_SUBSCRIPTION_MESSAGE,
                staticBackdrop: true,
                proceed: {
                    text: constants.UPDATE_SUBSCRIPTION,
                    action: updateSubscription.bind(
                        null,
                        plan,
                        props.setDialogMessage,
                        props.setLoading,
                        props.closeModal
                    ),
                    variant: 'success',
                },
                close: { text: constants.CANCEL },
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
                className="subscription-plan-selector"
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
                    className={`bold-text`}
                    style={{ color: '#aaa' }}
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
                        <span
                            className={`bold-text`}
                            style={{ fontSize: '20px' }}
                        >
                            {constants.YEARLY}
                        </span>

                        <Form.Switch
                            checked={planPeriod == PLAN_PERIOD.MONTH}
                            id={`plan-period-toggler`}
                            style={{ marginLeft: '15px', marginTop: '-4px' }}
                            className={`custom-switch-md`}
                            onChange={togglePeriod}
                        />
                        <span
                            className={`bold-text`}
                            style={{ fontSize: '20px' }}
                        >
                            {constants.MONTHLY}
                        </span>
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
                                        props.setDialogMessage({
                                            title:
                                                constants.CONFIRM_ACTIVATE_SUBSCRIPTION,
                                            content: constants.ACTIVATE_SUBSCRIPTION_MESSAGE(
                                                subscription.expiryTime
                                            ),
                                            staticBackdrop: true,
                                            proceed: {
                                                text:
                                                    constants.ACTIVATE_SUBSCRIPTION,
                                                action: activateSubscription.bind(
                                                    null,
                                                    props.setDialogMessage,
                                                    props.closeModal,
                                                    props.setLoading
                                                ),
                                                variant: 'success',
                                            },
                                            close: {
                                                text: constants.CANCEL,
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
                                        props.setDialogMessage({
                                            title:
                                                constants.CONFIRM_CANCEL_SUBSCRIPTION,
                                            content: constants.CANCEL_SUBSCRIPTION_MESSAGE(),
                                            staticBackdrop: true,
                                            proceed: {
                                                text:
                                                    constants.CANCEL_SUBSCRIPTION,
                                                action: cancelSubscription.bind(
                                                    null,
                                                    props.setDialogMessage,
                                                    props.closeModal,
                                                    props.setLoading
                                                ),
                                                variant: 'danger',
                                            },
                                            close: {
                                                text: constants.CANCEL,
                                            },
                                        })
                                    }
                                >
                                    {constants.CANCEL_SUBSCRIPTION}
                                </LinkButton>
                            )}
                            <LinkButton
                                variant="primary"
                                onClick={updatePaymentMethod.bind(
                                    null,
                                    props.setDialogMessage,
                                    props.setLoading
                                )}
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
