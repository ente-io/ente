import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export interface MessageAttributes {
    title?: string;
    staticBackdrop?: boolean;
    close?: { text?: string; variant?: string };
    proceed?: { text: string; action: any };
}
interface Props {
    show: boolean;
    children?: any;
    onHide: () => void;
    attributes?: MessageAttributes;
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
                    </Modal.Title>
                )}
                {children && (
                    <>
                        <hr /> {children}
                    </>
                )}
            </Modal.Body>
            {attributes && (
                <Modal.Footer style={{ borderTop: 'none' }}>
                    {attributes.close && (
                        <Button
                            variant={`outline-${
                                attributes.close?.variant ?? 'secondary'
                            }`}
                            onClick={props.onHide}
                        >
                            {attributes.close?.text ?? constants.OK}
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
