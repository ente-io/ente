import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

function ChangeDisabledMessage(props) {
    return (
        <Modal
            {...props}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Title id="contained-modal-title-vcenter">
                    {constants.SUBSCRIPTION_CHANGE_DISABLED}
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                <Button variant="secondary" onClick={props.onHide}>
                    {constants.CLOSE}
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default ChangeDisabledMessage;
