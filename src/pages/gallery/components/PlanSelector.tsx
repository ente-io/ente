import React, { useState } from 'react';
import { Modal, Spinner } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import subscriptionService, {
    Plan,
    Subscription,
} from 'services/subscriptionService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';

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
    plans: Plan[];
    modalView: boolean;
    closeModal: any;
    setBannerErrorCode;
}
function PlanSelector(props: Props) {
    const [loading, setLoading] = useState(false);
    const subscription: Subscription = getData(LS_KEYS.SUBSCRIPTION);
    const selectPlan = async (plan) => {
        try {
            setLoading(true);
            if (subscriptionService.hasActivePaidPlan()) {
                if (plan.androidID === subscription.productID) {
                    return;
                }
                await subscriptionService.updateSubscription(plan.stripeID);
            } else {
                await subscriptionService.buySubscription(plan.stripeID);
            }
        } catch (err) {
            props.setBannerErrorCode(err.message);
            setLoading(false);
            props.closeModal();
        }
    };
    const PlanIcons: JSX.Element[] = props.plans?.map((plan) => (
        <PlanIcon
            key={plan.stripeID}
            onClick={() => {
                selectPlan(plan);
            }}
            selected={plan.androidID === subscription.productID}
        >
            <span
                style={{
                    color: '#ECECEC',
                    fontWeight: 900,
                    fontSize: '72px',
                }}
            >
                {subscriptionService.convertBytesToGBs(plan.storage, 0)}
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
            {plan.androidID === subscription.productID && (
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
                    {subscriptionService.hasActivePaidPlan()
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
                {(!props.plans || loading) && (
                    <LoaderOverlay>
                        <Spinner animation="border" />
                    </LoaderOverlay>
                )}
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
