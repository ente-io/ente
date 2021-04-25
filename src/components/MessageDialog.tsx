import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export interface MessageAttributes {
    title?: string;
    staticBackdrop?: boolean;
    close?: { text?: string; variant?: string };
    proceed?: {
        text: string;
        action: any;
        variant: string;
        disabled?: boolean;
    };
    content?: any;
}
type Props = React.PropsWithChildren<{
    show: boolean;
    onHide: () => void;
    attributes: MessageAttributes;
}>;
export default function MessageDialog({
    attributes,
    children,
    ...props
}: Props) {
    if (!attributes) {
        return <Modal />;
    }
    return (
        <Modal
            {...props}
            size="lg"
            centered
            backdrop={attributes.staticBackdrop ? 'static' : 'true'}
        >
            <Modal.Header style={{ borderBottom: 'none' }}>
                {attributes.title && (
                    <Modal.Title>
                        <strong>{attributes.title}</strong>
                    </Modal.Title>
                )}
            </Modal.Header>
            {(children || attributes?.content) && (
                <Modal.Body style={{ borderTop: '1px solid #444' }}>
                    {children ? children : <h5>{attributes.content}</h5>}
                </Modal.Body>
            )}
            <Modal.Footer style={{ borderTop: 'none' }}>
                {attributes.close && (
                    <Button
                        variant={`outline-${
                            attributes.close?.variant ?? 'secondary'
                        }`}
                        onClick={props.onHide}
                        style={{
                            padding: '6px 3em',
                            marginRight: '20px',
                        }}
                    >
                        {attributes.close?.text ?? constants.OK}
                    </Button>
                )}
                {attributes.proceed && (
                    <Button
                        variant={`outline-${
                            attributes.proceed?.variant ?? 'primary'
                        }`}
                        onClick={() => {
                            attributes.proceed.action();
                            props.onHide();
                        }}
                        style={{ padding: '6px 3em', marginRight: '20px' }}
                        disabled={attributes.proceed.disabled}
                    >
                        {attributes.proceed.text}
                    </Button>
                )}
            </Modal.Footer>
        </Modal>
    );
}
