import { Close } from '@mui/icons-material';
import { Box, IconButton, Typography } from '@mui/material';
import React from 'react';

interface Iprops {
    title: string;
    caption?: string;
    onClose: () => void;
}

export default function Titlebar({
    title,
    caption,
    onClose,
}: Iprops): JSX.Element {
    return (
        <>
            <Box display={'flex'} height={48} alignItems={'center'}>
                <IconButton onClick={onClose} color="secondary">
                    <Close />
                </IconButton>
            </Box>
            <Box py={0.5} px={2} height={54}>
                <Typography variant="h3" fontWeight={'bold'}>
                    {title}
                </Typography>
                <Typography variant="body2">{caption}</Typography>
            </Box>
        </>
    );
}
