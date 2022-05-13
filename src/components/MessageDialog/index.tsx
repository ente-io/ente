import React from 'react';
import constants from 'utils/strings/constants';
import {
    Breakpoint,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    Divider,
} from '@mui/material';
import DialogTitleWithCloseButton from './TitleWithCloseButton';

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
        <Dialog open={props.show} maxWidth={props.size} onClose={props.onHide}>
            {attributes.title && (
                <>
                    <DialogTitleWithCloseButton
                        onClose={
                            attributes.nonClosable ? () => null : props.onHide
                        }>
                        {attributes.title}
                    </DialogTitleWithCloseButton>
                    <Divider />
                </>
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
                <DialogActions sx={{ m: '10px 10px' }}>
                    <>
                        {attributes.close && (
                            <Button
                                fullWidth
                                variant="outlined"
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
                                fullWidth
                                variant="outlined"
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
        </Dialog>
    );
}
