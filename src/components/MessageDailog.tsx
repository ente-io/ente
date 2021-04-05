import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

interface Props {
    show: boolean;
    children?: any;
    onHide: () => void;
    attributes?: {
        title?: string;
        ok?: boolean;
        staticBackdrop?: boolean;
        cancel?: { text: string; action?: any };
        proceed?: { text: string; action: any };
    };
}
export function MessageDialog({ attributes, children, ...props }: Props) {
    return (
        <Modal
            {...props}
            size="lg"
            centered
            backdrop={attributes?.staticBackdrop ? 'static' : 'true'}
        >
            <Modal.Body>
                {attributes?.title && (
                    <Modal.Title>
                        <strong>{attributes.title}</strong>
                        <hr />
                    </Modal.Title>
                )}
                {children}
            </Modal.Body>
            {attributes && (
                <Modal.Footer style={{ borderTop: 'none' }}>
                    {attributes.ok && (
                        <Button variant="secondary" onClick={props.onHide}>
                            {constants.OK}
                        </Button>
                    )}
                    {attributes.cancel && (
                        <Button
                            variant="outline-danger"
                            onClick={attributes.cancel.action ?? props.onHide}
                        >
                            {attributes.cancel.text}
                        </Button>
                    )}
                    {attributes.proceed && (
                        <Button
                            variant="outline-success"
                            onClick={attributes.proceed.action}
                        >
                            {attributes.proceed.text}
                        </Button>
                    )}
                </Modal.Footer>
            )}
        </Modal>
    );
}
