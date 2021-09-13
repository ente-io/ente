import React, { useEffect, useState } from 'react';
import { Form, Modal, Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import billingService, { Plan, Subscription } from 'services/billingService';
import {
    convertBytesToGBs,
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
    planForSubscription,
} from 'utils/billingUtil';
import { reverseString } from 'utils/common';
import { SetDialogMessage } from 'components/MessageDialog';
import ArrowEast from 'components/icons/ArrowEast';
import LinkButton from './LinkButton';
import { DeadCenter, SetLoading } from 'pages/gallery';

export const PlanIcon = styled.div<{ selected: boolean }>`
    border-radius: 20px;
    width: 220px;
    border: 2px solid #333;
    padding: 30px;
    margin: 10px;
    text-align: center;
    font-size: 20px;
    background-color: #ffffff00;
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    cursor: ${(props) => (props.selected ? 'not-allowed' : 'pointer')};
    border-color: ${(props) => props.selected && '#56e066'};
    transition: all 0.3s ease-out;
    overflow: hidden;
    position: relative;

    & > div:first-child::before {
        content: ' ';
        height: 600px;
        width: 50px;
        background-color: #444;
        left: 0;
        top: -50%;
        position: absolute;
        transform: rotate(45deg) translateX(-200px);
        transition: all 0.5s ease-out;
    }

    &:hover {
        transform: scale(1.1);
        background-color: #ffffff11;
    }

    &:hover > div:first-child::before {
        transform: rotate(45deg) translateX(300px);
    }
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
    const [plans, setPlans] = useState<Plan[]>(null);
    const [planPeriod, setPlanPeriod] = useState<PLAN_PERIOD>(PLAN_PERIOD.YEAR);
    const togglePeriod = () => {
        setPlanPeriod((prevPeriod) =>
            prevPeriod === PLAN_PERIOD.MONTH
                ? PLAN_PERIOD.YEAR
                : PLAN_PERIOD.MONTH
        );
    };
    useEffect(() => {
        if (props.modalView) {
            const main = async () => {
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
                props.setLoading(false);
            };
            main();
        }
    }, [props.modalView]);

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
                await billingService.buySubscription(plan.stripeID);
            } catch (e) {
                props.setLoading(false);
                props.setDialogMessage({
                    title: constants.ERROR,
                    content: constants.SUBSCRIPTION_PURCHASE_FAILED,
                    close: { variant: 'danger' },
                });
            }
        }
    }

    const PlanIcons: JSX.Element[] = plans
        ?.filter((plan) => plan.period === planPeriod)
        ?.map((plan) => (
            <PlanIcon
                key={plan.stripeID}
                className="subscription-plan-selector"
                selected={isUserSubscribedPlan(plan, subscription)}
                onClick={async () => await onPlanSelect(plan)}>
                <div>
                    <span
                        style={{
                            color: '#ECECEC',
                            fontWeight: 900,
                            fontSize: '40px',
                            lineHeight: '40px',
                        }}>
                        {convertBytesToGBs(plan.storage, 0)}
                    </span>
                    <span
                        style={{
                            color: '#858585',
                            fontSize: '24px',
                            fontWeight: 900,
                        }}>
                        {' '}
                        GB
                    </span>
                </div>
                <div
                    className="bold-text"
                    style={{
                        color: '#aaa',
                        lineHeight: '36px',
                        fontSize: '20px',
                    }}>
                    {`${plan.price} / ${plan.period}`}
                </div>
                <Button
                    variant="outline-success"
                    block
                    style={{
                        marginTop: '20px',
                        fontSize: '14px',
                        display: 'flex',
                        justifyContent: 'center',
                    }}
                    disabled={isUserSubscribedPlan(plan, subscription)}>
                    {constants.CHOOSE_PLAN_BTN}
                    <ArrowEast style={{ marginLeft: '5px' }} />
                </Button>
            </PlanIcon>
        ));
    return (
        <Modal
            show={props.modalView}
            onHide={props.closeModal}
            size="xl"
            centered
            backdrop={hasPaidSubscription(subscription) ? true : 'static'}
            contentClassName="plan-selector-modal-content">
            <Modal.Header closeButton>
                <Modal.Title
                    style={{
                        marginLeft: '12px',
                        width: '100%',
                        textAlign: 'center',
                    }}>
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
                            className="bold-text"
                            style={{ fontSize: '16px' }}>
                            {constants.MONTHLY}
                        </span>

                        <Form.Switch
                            checked={planPeriod === PLAN_PERIOD.YEAR}
                            id="plan-period-toggler"
                            style={{
                                margin: '-4px 0 20px 15px',
                                fontSize: '10px',
                            }}
                            className="custom-switch-md"
                            onChange={togglePeriod}
                        />
                        <span
                            className="bold-text"
                            style={{ fontSize: '16px' }}>
                            {constants.YEARLY}
                        </span>
                    </div>
                </DeadCenter>
                <div
                    style={{
                        display: 'flex',
                        justifyContent: 'space-around',
                        flexWrap: 'wrap',
                        minHeight: '212px',
                        margin: '5px 0',
                    }}>
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
                                            title: constants.CONFIRM_ACTIVATE_SUBSCRIPTION,
                                            content:
                                                constants.ACTIVATE_SUBSCRIPTION_MESSAGE(
                                                    subscription.expiryTime
                                                ),
                                            staticBackdrop: true,
                                            proceed: {
                                                text: constants.ACTIVATE_SUBSCRIPTION,
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
                                    }>
                                    {constants.ACTIVATE_SUBSCRIPTION}
                                </LinkButton>
                            ) : (
                                <LinkButton
                                    variant="danger"
                                    onClick={() =>
                                        props.setDialogMessage({
                                            title: constants.CONFIRM_CANCEL_SUBSCRIPTION,
                                            content:
                                                constants.CANCEL_SUBSCRIPTION_MESSAGE(),
                                            staticBackdrop: true,
                                            proceed: {
                                                text: constants.CANCEL_SUBSCRIPTION,
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
                                    }>
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
                                style={{ marginTop: '20px' }}>
                                {constants.MANAGEMENT_PORTAL}
                            </LinkButton>
                        </>
                    ) : (
                        <LinkButton
                            variant="primary"
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
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
