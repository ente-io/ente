import React from 'react';
import constants from 'utils/strings/constants';
import {
    Breakpoint,
    Button,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
} from '@mui/material';
import MessageDialogBase from './MessageDialogBase';

export type ButtonColors =
    | 'inherit'
    | 'secondary'
    | 'primary'
    | 'success'
    | 'error'
    | 'info'
    | 'warning'
    | 'danger';

export interface MessageAttributes {
    title?: string;
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    content?: any;
    close?: { text?: string; variant?: ButtonColors; action?: () => void };
    proceed?: {
        text: string;
        action: () => void;
        variant: ButtonColors;
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
            onClose={!attributes.nonClosable && props.onHide}>
            {attributes.title && (
                <DialogTitle
                    sx={{
                        p: 0,
                        pb: 2,
                        fontSize: (theme) => theme.typography.h5,
                    }}>
                    {attributes.title}
                </DialogTitle>
            )}
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
