import React, { useState } from 'react';
import { Modal, Spinner } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import subscriptionService, { Plan } from 'services/subscriptionService';

export const PlanIcon = styled.div`
    height: 192px;
    width: 250px;
    border: 1px solid #555;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    cursor: pointer;
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
}
function PlanSelector(props: Props) {
    const [loading, setLoading] = useState(false);
    const PlanIcons: JSX.Element[] = props.plans?.map((plan) => (
        <PlanIcon
            key={plan.stripeID}
            onClick={() => {
                setLoading(true);
                subscriptionService.buySubscription(plan.stripeID);
            }}
        >
            {plan.androidID}
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
                    {constants.CHOOSE_PLAN}
                </Modal.Title>
            </Modal.Header>
            <Modal.Body
                style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    flexWrap: 'wrap',
                }}
            >
                {PlanIcons}
                {loading && (
                    <LoaderOverlay>
                        <Spinner animation="border" />
                    </LoaderOverlay>
                )}
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
