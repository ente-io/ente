import React from 'react';
import { Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import { ImageContainer } from './AddCollection';
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

interface Props {
    plans: Plan[];
    modalView: boolean;
    closeModal: any;
}
function PlanSelector(props: Props) {
    const PlanIcons: JSX.Element[] = props.plans?.map((plan) => (
        <PlanIcon
            key={plan.stripeID}
            onClick={() => subscriptionService.buySubscription(plan.stripeID)}
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
            </Modal.Body>
        </Modal>
    );
}

export default PlanSelector;
