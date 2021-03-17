import React, { useState } from 'react';
import { Modal, Spinner } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import subscriptionService, {
    Plan,
    Subscription,
} from 'services/subscriptionService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import {
    convertBytesToGBs,
    getPlans,
    getUserSubscription,
    hasActivePaidPlan,
} from 'utils/billingUtil';

export const PlanIcon = styled.div<{ selected: boolean }>`
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
    setBannerMessage;
}
function PlanSelector(props: Props) {
    const [loading, setLoading] = useState(false);
    const subscription = getUserSubscription();
    const plans = getPlans();
    const selectPlan = async (plan) => {
        try {
            setLoading(true);
            if (hasActivePaidPlan(subscription)) {
                if (plan.androidID === subscription.productID) {
                    return;
                }
                await subscriptionService.updateSubscription(plan.stripeID);
            } else {
                await subscriptionService.buySubscription(plan.stripeID);
            }
        } catch (err) {
            props.setBannerMessage({
                message: constants.SUBSCRIPTION_PURCHASE_FAILED,
                variant: 'danger',
            });
            props.closeModal();
        } finally {
            setLoading(false);
            setTimeout(() => {
                props.setBannerMessage({
                    message: constants.SUBSCRIPTION_UPDATE_SUCCESS,
                    variant: 'success',
                });
                props.closeModal();
            }, 300);
        }
    };
    const PlanIcons: JSX.Element[] = plans?.map((plan) => (
        <PlanIcon
            key={plan.stripeID}
            onClick={() => {
                selectPlan(plan);
            }}
            selected={plan.androidID === subscription?.productID}
        >
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
                style={{ color: '#858585', fontSize: '24px', fontWeight: 900 }}
            >
                {' '}
                GB
            </span>
            <div
                style={{
                    color: '#ECECEC',
                    lineHeight: '24px',
                    fontSize: '24px',
                }}
            >
                {`${plan.price} / ${constants.MONTH}`}
            </div>
            {plan.androidID === subscription?.productID && (
                <div
                    style={{
                        color: '#ECECEC',
                        lineHeight: '24px',
                        fontSize: '24px',
                        marginTop: '20px',
                    }}
                >
                    current plan
                </div>
            )}
        </PlanIcon>
    ));
    return (
        <Modal
            show={props.modalView}
            onHide={props.closeModal}
            dialogClassName="modal-90w"
            style={{ maxWidth: '100%' }}
        >
            <Modal.Header closeButton>
                <Modal.Title style={{ marginLeft: '12px' }}>
                    {hasActivePaidPlan(subscription)
                        ? constants.MANAGE_PLAN
                        : constants.CHOOSE_PLAN}
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
