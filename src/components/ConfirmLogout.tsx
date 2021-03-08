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
            <Modal.Header closeButton>
                <Modal.Title
                    id="contained-modal-title-vcenter"
                    className="text-center"
                >
                    {constants.LOGOUT}
                </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <strong>{constants.LOGOUT_WARNING}</strong>
            </Modal.Body>
            <Modal.Footer>
                <Button variant="primary" onClick={props.onHide}>
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
