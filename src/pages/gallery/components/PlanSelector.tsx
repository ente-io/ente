import React, { useState } from 'react';
import { Form, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import billingService, { Plan, Subscription } from 'services/billingService';
import {
    convertBytesToGBs,
    getPlans,
    getUserSubscription,
    hasPaidPlan,
    isUserSubscribedPlan,
    isSubscriptionCancelled,
    updatePaymentMethod,
    SetConfirmAction,
    SetDialogMessage,
    SetLoading,
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
    setSelectedPlan;
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

    async function onPlanSelect(plan: Plan) {
        props.setSelectedPlan(plan);
        if (hasPaidPlan(subscription)) {
            props.setConfirmAction(CONFIRM_ACTION.UPDATE_SUBSCRIPTION);
        } else {
            props.setLoading(true);
            await billingService.buyPaidSubscription(plan.stripeID);
            props.setLoading(false);
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
                >{`${plan.price} / ${plan.period}`}</div>
            </PlanIcon>
        ));
    return (
        <Modal
            show={props.modalView}
            onHide={props.closeModal}
            dialogClassName="modal-90w"
            style={{ maxWidth: '100%' }}
            centered
            backdrop={`static`}
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
                        {hasPaidPlan(subscription)
                            ? constants.MANAGE_PLAN
                            : constants.CHOOSE_PLAN}
                    </span>
                </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <DeadCenter>
                    <div style={{ display: 'flex' }}>
                        <span className={`bold-text`}>{constants.YEARLY}</span>

                        <Form.Switch
                            checked={planPeriod == PLAN_PERIOD.MONTH}
                            id={`plan-period-toggler`}
                            style={{ marginLeft: '15px', marginTop: '-4px' }}
                            className={`custom-switch-md`}
                            onChange={togglePeriod}
                        />
                        <span className={`bold-text`}>{constants.MONTHLY}</span>
                    </div>
                </DeadCenter>
                <div
                    style={{
                        display: 'flex',
                        justifyContent: 'space-around',
                        flexWrap: 'wrap',
                        margin: '4% 0',
                    }}
                >
                    {!plans ? (
                        <LoadingOverlay>
                            <EnteSpinner />
                        </LoadingOverlay>
                    ) : (
                        PlanIcons
                    )}
                </div>
                <DeadCenter style={{ marginBottom: '30px' }}>
                    {hasPaidPlan(subscription) ? (
                        <>
                            <LinkButton
                                variant="secondary"
                                onClick={(event) =>
                                    updatePaymentMethod(
                                        event,
                                        props.setDialogMessage,
                                        props.setLoading
                                    )
                                }
                            >
                                {constants.MANAGEMENT_PORTAL}
                            </LinkButton>
                            {isSubscriptionCancelled(subscription) ? (
                                <LinkButton
                                    variant="success"
                                    onClick={() =>
                                        props.setConfirmAction(
                                            CONFIRM_ACTION.ACTIVATE_SUBSCRIPTION
                                        )
                                    }
                                >
                                    {constants.ACTIVATE_SUBSCRIPTION}
                                </LinkButton>
                            ) : (
                                <LinkButton
                                    variant="danger"
                                    onClick={() =>
                                        props.setConfirmAction(
                                            CONFIRM_ACTION.CANCEL_SUBSCRIPTION
                                        )
                                    }
                                >
                                    {constants.CANCEL_SUBSCRIPTION}
                                </LinkButton>
                            )}
                        </>
                    ) : (
                        <LinkButton
                            variant="secondary"
                            onClick={props.closeModal}
                        >
                            {constants.SKIP}
                        </LinkButton>
                    )}
                </DeadCenter>
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
