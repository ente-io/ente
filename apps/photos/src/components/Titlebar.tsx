import Close from '@mui/icons-material/Close';
import ArrowBack from '@mui/icons-material/ArrowBack';
import { Box, IconButton, Typography } from '@mui/material';
import React from 'react';
import { FlexWrapper } from './Container';

interface Iprops {
    title: string;
    caption?: string;
    onClose: () => void;
    backIsClose?: boolean;
    onRootClose?: () => void;
    actionButton?: JSX.Element;
}

export default function Titlebar({
    title,
    caption,
    onClose,
    backIsClose,
    actionButton,
    onRootClose,
}: Iprops): JSX.Element {
    return (
        <>
            <FlexWrapper
                height={48}
                alignItems={'center'}
                justifyContent="space-between">
                <IconButton
                    onClick={onClose}
                    color={backIsClose ? 'secondary' : 'primary'}>
                    {backIsClose ? <Close /> : <ArrowBack />}
                </IconButton>
                <Box display={'flex'} gap="4px">
                    {actionButton && actionButton}
                    {!backIsClose && (
                        <IconButton onClick={onRootClose} color={'secondary'}>
                            <Close />
                        </IconButton>
                    )}
                </Box>
            </FlexWrapper>
            <Box py={0.5} px={2}>
                <Typography variant="h3" fontWeight={'bold'}>
                    {title}
                </Typography>
                <Typography
                    variant="small"
                    color="text.muted"
                    sx={{ wordBreak: 'break-all', minHeight: '17px' }}>
                    {caption}
                </Typography>
            </Box>
        </>
    );
}
