import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

function ConfirmLogout({ logout, ...props }) {
    return (
        <Modal
            {...props}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Title id="contained-modal-title-vcenter">
                    {constants.LOGOUT_WARNING}
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                <Button variant="secondary" onClick={props.onHide}>
                    {constants.CANCEL}
                </Button>
                <Button variant="danger" onClick={logout}>
                    {constants.LOGOUT}
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default ConfirmLogout;
