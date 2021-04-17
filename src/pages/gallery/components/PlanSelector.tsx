import React, { useState } from 'react';
import { Button, Modal, Spinner } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import billingService, {
    PAYMENT_INTENT_STATUS,
    Plan,
    Subscription,
} from 'services/billingService';
import {
    convertBytesToGBs,
    getPlans,
    getUserSubscription,
    hasPaidPlan,
    isSubscribed,
    isUserRenewingPlan,
} from 'utils/billingUtil';
import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import { SUBSCRIPTION_VERIFICATION_ERROR } from 'utils/common/errorUtil';

export const PlanIcon = styled.div<{ selected: boolean }>`
    padding-top: 20px;
    border-radius: 10%;
    height: 192px;
    width: 250px;
    border: 1px solid #404040;
    text-align: center;
    font-size: 20px;
    cursor: ${(props) => (props.selected ? 'not-allowed' : 'pointer')};
    background: ${(props) => props.selected && '#404040'};
`;

const LoaderOverlay = styled.div`
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    position: absolute;
    z-index: 9;
    color: white;
    align-items: center;
`;

interface Props {
    modalView: boolean;
    closeModal: any;
    setDialogMessage;
    setConfirmAction;
}
enum PLAN_PERIOD {
    MONTH = 'month',
    YEAR = 'year',
}
function PlanSelector(props: Props) {
    const [loading, setLoading] = useState(false);
    const subscription: Subscription = getUserSubscription();
    const plans = getPlans();
    const [planPeriod, setPlanPeriod] = useState<PLAN_PERIOD>(
        PLAN_PERIOD.MONTH
    );
    const togglePeriod = () => {
        setPlanPeriod((prevPeriod) =>
            prevPeriod == PLAN_PERIOD.MONTH
                ? PLAN_PERIOD.YEAR
                : PLAN_PERIOD.MONTH
        );
    };
    const selectPlan = async (plan: Plan) => {
        try {
            setLoading(true);
            if (hasPaidPlan(subscription)) {
                await billingService.updateSubscription(plan.stripeID);
                setLoading(false);
                await new Promise((resolve) =>
                    setTimeout(() => resolve(null), 400)
                );
            } else {
                await billingService.buySubscription(plan.stripeID);
            }
            props.setDialogMessage({
                title: constants.SUBSCRIPTION_UPDATE_SUCCESS,
                close: { variant: 'success' },
            });
        } catch (err) {
            switch (err?.message) {
                case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                    props.setConfirmAction(
                        CONFIRM_ACTION.UPDATE_PAYMENT_METHOD
                    );
                    break;
                case SUBSCRIPTION_VERIFICATION_ERROR:
                    props.setDialogMessage({
                        title: constants.SUBSCRIPTION_VERIFICATION_FAILED,
                        close: { variant: 'danger' },
                    });
                    break;
                default:
                    props.setDialogMessage({
                        title: constants.SUBSCRIPTION_PURCHASE_FAILED,
                        close: { variant: 'danger' },
                    });
            }
        } finally {
            setLoading(false);
            props.closeModal();
        }
    };

    const PlanIcons: JSX.Element[] = plans
        ?.filter((plan) => plan.period == planPeriod)
        ?.map((plan) => (
            <PlanIcon
                key={plan.stripeID}
                onClick={() =>
                    !isUserRenewingPlan(plan, subscription) && selectPlan(plan)
                }
                selected={isUserRenewingPlan(plan, subscription)}
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
                    style={{
                        color: '#ECECEC',
                        lineHeight: '24px',
                        fontSize: '24px',
                    }}
                >
                    {`${plan.price} / ${plan.period}`}
                </div>
                {isUserRenewingPlan(plan, subscription) && 'active'}
            </PlanIcon>
        ));
    return (
        <Modal
            show={props.modalView}
            onHide={props.closeModal}
            dialogClassName="modal-90w"
            style={{ maxWidth: '100%' }}
        >
            <Modal.Header>
                <Modal.Title
                    style={{
                        marginLeft: '12px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        width: '100%',
                    }}
                >
                    <span>
                        {isSubscribed(subscription)
                            ? constants.MANAGE_PLAN
                            : constants.CHOOSE_PLAN}
                    </span>
                    <span>
                        <Button
                            variant="outline-primary"
                            onClick={togglePeriod}
                        >
                            <div style={{ fontSize: '20px', width: '80px' }}>
                                {planPeriod}
                                {'ly'}
                            </div>
                        </Button>
                    </span>
                </Modal.Title>
            </Modal.Header>
            <Modal.Body
                style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    flexWrap: 'wrap',
                    minHeight: '150px',
                }}
            >
                {PlanIcons}
                {(!plans || loading) && (
                    <LoaderOverlay>
                        <Spinner animation="border" />
                    </LoaderOverlay>
                )}
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
