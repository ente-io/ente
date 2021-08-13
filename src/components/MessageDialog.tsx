import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export interface MessageAttributes {
    title?: string;
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    content?: any;
    close?: { text?: string; variant?: string; action?: () => void };
    proceed?: {
        text: string;
        action: () => void;
        variant: string;
        disabled?: boolean;
    };
}

export type SetDialogMessage = React.Dispatch<
    React.SetStateAction<MessageAttributes>
>;
type Props = React.PropsWithChildren<{
    show: boolean;
    onHide: () => void;
    attributes: MessageAttributes;
    size?: 'sm' | 'lg' | 'xl';
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
            onHide={attributes.nonClosable ? () => null : props.onHide}
            centered
            backdrop={attributes.staticBackdrop ? 'static' : 'true'}>
            <Modal.Header
                style={{ borderBottom: 'none' }}
                closeButton={!attributes.nonClosable}>
                {attributes.title && (
                    <Modal.Title>{attributes.title}</Modal.Title>
                )}
            </Modal.Header>
            {(children || attributes?.content) && (
                <Modal.Body style={{ borderTop: '1px solid #444' }}>
                    {children || (
                        <p style={{ fontSize: '1.25rem', marginBottom: 0 }}>
                            {attributes.content}
                        </p>
                    )}
                </Modal.Body>
            )}
            {(attributes.close || attributes.proceed) && (
                <Modal.Footer style={{ borderTop: 'none' }}>
                    <div
                        style={{
                            display: 'flex',
                            flexWrap: 'wrap',
                        }}>
                        {attributes.close && (
                            <Button
                                variant={`outline-${
                                    attributes.close?.variant ?? 'secondary'
                                }`}
                                onClick={() => {
                                    attributes.close?.action
                                        ? attributes.close?.action()
                                        : props.onHide();
                                }}
                                style={{
                                    padding: '6px 3em',
                                    margin: '0 20px',
                                    marginBottom: '20px',
                                    flex: 1,
                                    whiteSpace: 'nowrap',
                                }}>
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
                                style={{
                                    padding: '6px 3em',
                                    margin: '0 20px',
                                    marginBottom: '20px',
                                    flex: 1,
                                    whiteSpace: 'nowrap',
                                }}
                                disabled={attributes.proceed.disabled}>
                                {attributes.proceed.text}
                            </Button>
                        )}
                    </div>
                </Modal.Footer>
            )}
        </Modal>
    );
}
