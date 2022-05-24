import React from 'react';
import constants from 'utils/strings/constants';
import {
    Breakpoint,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogProps,
} from '@mui/material';
import DialogTitleWithCloseButton from './titleWithCloseButton';
import MessageText from './messageText';
import DialogBoxBase from './base';
import { DialogBoxAttributes } from 'types/dialogBox';

type IProps = React.PropsWithChildren<
    Omit<DialogProps, 'onClose' | 'maxSize'> & {
        onClose: () => void;
        attributes: DialogBoxAttributes;
        size?: Breakpoint;
        titleCloseButton?: boolean;
    }
>;

export default function DialogBox({ attributes, children, ...props }: IProps) {
    if (!attributes) {
        return <Dialog open={false} />;
    }

    const handleClose: DialogProps['onClose'] = (_, reason) => {
        if (attributes?.nonClosable) {
            // no-op
        } else if (attributes?.staticBackdrop && reason === 'backdropClick') {
            // no-op
        } else {
            props.onClose();
        }
    };

    return (
        <DialogBoxBase
            open={props.open}
            maxWidth={props.size}
            onClose={handleClose}
            {...props}>
            {attributes.title && (
                <DialogTitleWithCloseButton
                    onClose={
                        !attributes?.nonClosable &&
                        props.titleCloseButton &&
                        handleClose
                    }>
                    {attributes.title}
                </DialogTitleWithCloseButton>
            )}
            {(children || attributes?.content) && (
                <DialogContent>
                    {children || (
                        <MessageText>{attributes.content}</MessageText>
                    )}
                </DialogContent>
            )}
            {(attributes.close || attributes.proceed) && (
                <DialogActions>
                    <>
                        {attributes.close && (
                            <Button
                                color={attributes.close?.variant ?? 'secondary'}
                                onClick={() => {
                                    attributes.close.action &&
                                        attributes.close?.action();
                                    props.onClose();
                                }}>
                                {attributes.close?.text ?? constants.OK}
                            </Button>
                        )}
                        {attributes.proceed && (
                            <Button
                                color={attributes.proceed?.variant}
                                onClick={() => {
                                    attributes.proceed.action();
                                    props.onClose();
                                }}
                                disabled={attributes.proceed.disabled}>
                                {attributes.proceed.text}
                            </Button>
                        )}
                    </>
                </DialogActions>
            )}
        </DialogBoxBase>
    );
}
