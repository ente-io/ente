import React from 'react';
import constants from 'utils/strings/constants';
import {
    Breakpoint,
    Button,
    ButtonProps,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
} from '@mui/material';
import MessageDialogBase from './MessageDialogBase';

export interface MessageAttributes {
    title?: string;
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    content?: any;
    close?: {
        text?: string;
        variant?: ButtonProps['color'];
        action?: () => void;
    };
    proceed?: {
        text: string;
        action: () => void;
        variant: ButtonProps['color'];
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
    size?: Breakpoint;
}>;

export default function MessageDialog({
    attributes,
    children,
    ...props
}: Props) {
    if (!attributes) {
        return <></>;
    }

    return (
        <MessageDialogBase
            open={props.show}
            maxWidth={props.size}
            fullWidth
            staticBackDrop={attributes.staticBackdrop}
            onClose={attributes.nonClosable ? props.onHide : () => null}>
            {attributes.title && <DialogTitle>{attributes.title}</DialogTitle>}
            {(children || attributes?.content) && (
                <DialogContent>
                    {children || (
                        <DialogContentText>
                            {attributes.content}
                        </DialogContentText>
                    )}
                </DialogContent>
            )}
            {(attributes.close || attributes.proceed) && (
                <DialogActions>
                    <>
                        {attributes.close && (
                            <Button
                                variant="contained"
                                color={attributes.close?.variant ?? 'secondary'}
                                onClick={() => {
                                    attributes.close.action &&
                                        attributes.close?.action();
                                    props.onHide();
                                }}>
                                {attributes.close?.text ?? constants.OK}
                            </Button>
                        )}
                        {attributes.proceed && (
                            <Button
                                variant="contained"
                                color={attributes.proceed?.variant ?? 'primary'}
                                onClick={() => {
                                    attributes.proceed.action();
                                    props.onHide();
                                }}
                                disabled={attributes.proceed.disabled}>
                                {attributes.proceed.text}
                            </Button>
                        )}
                    </>
                </DialogActions>
            )}
        </MessageDialogBase>
    );
}
