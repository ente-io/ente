import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export enum CONFIRM_ACTION {
    LOGOUT,
    DELETE,
    SESSION_EXPIRED,
    DOWNLOAD_APP,
}

const CONFIRM_ACTION_VALUES = [
    { text: 'LOGOUT', type: 'danger' },
    { text: 'DELETE', type: 'danger' },
    { text: 'SESSION_EXPIRED', type: 'primary' },
    { text: 'DOWNLOAD_APP', type: 'primary' },
];

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
                    {
                        constants[
                            `${CONFIRM_ACTION_VALUES[action]?.text}_WARNING`
                        ]
                    }
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                {action != CONFIRM_ACTION.SESSION_EXPIRED && (
                    <Button variant="secondary" onClick={props.onHide}>
                        {constants.CANCEL}
                    </Button>
                )}
                <Button
                    variant={`${CONFIRM_ACTION_VALUES[action]?.type}`}
                    onClick={callback}
                >
                    {constants[CONFIRM_ACTION_VALUES[action]?.text]}
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default ConfirmDialog;
