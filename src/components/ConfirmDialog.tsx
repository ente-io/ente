import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export enum CONFIRM_ACTION {
    LOGOUT = 'LOGOUT',
    DELETE = 'DELETE',
    SESSION_EXPIRED = 'SESSION_EXPIRED',
}

export interface Props {
    callback: any;
    action: CONFIRM_ACTION;
    show: boolean;
    onHide: () => void;
}
function ConfirmDialog({ callback, action, ...props }: Props) {
    return (
        <Modal
            {...props}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
            backdrop={
                action == CONFIRM_ACTION.SESSION_EXPIRED ? 'static' : 'true'
            }
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Title id="contained-modal-title-vcenter">
                    {constants[`${action}_WARNING`]}
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                {action != CONFIRM_ACTION.SESSION_EXPIRED && (
                    <Button variant="secondary" onClick={props.onHide}>
                        {constants.CANCEL}
                    </Button>
                )}
                <Button variant="danger" onClick={callback}>
                    {constants[action]}
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default ConfirmDialog;
