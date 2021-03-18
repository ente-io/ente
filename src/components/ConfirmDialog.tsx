import React, { MouseEventHandler } from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

interface Props {
    callback?: Map<string, Function>;
    action: string;
    show: boolean;
    onHide: MouseEventHandler<HTMLElement>;
}
function ConfirmDialog(props: Props) {
    const { callback, action, ...rest } = props;
    return (
        <Modal
            {...rest}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Title id="contained-modal-title-vcenter">
                    {constants[`${String(action).toUpperCase()}_WARNING`]}
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                <Button variant="secondary" onClick={props.onHide}>
                    {constants.CLOSE}
                </Button>
                {action && (
                    <Button variant="danger" onClick={callback[action]}>
                        {constants[String(action).toUpperCase()]}
                    </Button>
                )}
            </Modal.Footer>
        </Modal>
    );
}
export default ConfirmDialog;
