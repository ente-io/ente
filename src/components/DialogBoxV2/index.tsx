import React from 'react';
import {
    Box,
    Breakpoint,
    Button,
    Dialog,
    DialogProps,
    Stack,
    Typography,
} from '@mui/material';
import { t } from 'i18next';
import { dialogCloseHandler } from 'components/DialogBox/TitleWithCloseButton';
import { DialogBoxAttributesV2 } from 'types/dialogBox';

type IProps = React.PropsWithChildren<
    Omit<DialogProps, 'onClose' | 'maxSize'> & {
        onClose: () => void;
        attributes: DialogBoxAttributesV2;
        size?: Breakpoint;
        titleCloseButton?: boolean;
    }
>;

export default function DialogBoxV2({
    attributes,
    children,
    open,
    onClose,
    ...props
}: IProps) {
    if (!attributes) {
        return <></>;
    }

    const handleClose = dialogCloseHandler({
        staticBackdrop: attributes.staticBackdrop,
        nonClosable: attributes.nonClosable,
        onClose: onClose,
    });

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            {...props}
            PaperProps={{
                sx: {
                    padding: '8px 12px',
                    maxWidth: '360px',
                },
            }}>
            <Stack spacing={'36px'} p={'16px'}>
                <Stack spacing={'19px'}>
                    {attributes.icon && (
                        <Box
                            sx={{
                                '& > svg': {
                                    fontSize: '32px',
                                },
                            }}>
                            {attributes.icon}
                        </Box>
                    )}
                    {attributes.title && (
                        <Typography variant="large" fontWeight={'bold'}>
                            {attributes.title}
                        </Typography>
                    )}
                    {children ||
                        (attributes?.content && (
                            <Typography color="text.muted">
                                {attributes.content}
                            </Typography>
                        ))}
                </Stack>
                <Stack
                    spacing={'8px'}
                    direction={
                        attributes.buttonDirection === 'row'
                            ? 'row-reverse'
                            : 'column'
                    }
                    flex={1}>
                    {attributes.proceed && (
                        <Button
                            size="large"
                            color={attributes.proceed?.variant}
                            onClick={() => {
                                attributes.proceed.action();
                                onClose();
                            }}
                            disabled={attributes.proceed.disabled}>
                            {attributes.proceed.text}
                        </Button>
                    )}
                    {attributes.close && (
                        <Button
                            size="large"
                            color={attributes.close?.variant ?? 'secondary'}
                            onClick={() => {
                                attributes.close.action &&
                                    attributes.close?.action();
                                onClose();
                            }}>
                            {attributes.close?.text ?? t('OK')}
                        </Button>
                    )}
                    {attributes.buttons &&
                        attributes.buttons.map((b) => (
                            <Button
                                size="large"
                                key={b.text}
                                color={b.variant}
                                onClick={() => {
                                    b.action();
                                    onClose();
                                }}
                                disabled={b.disabled}>
                                {b.text}
                            </Button>
                        ))}
                </Stack>
            </Stack>
        </Dialog>
    );
}
