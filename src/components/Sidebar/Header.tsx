import { Typography, IconButton } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';
import CloseIcon from '@mui/icons-material/Close';

interface IProps {
    closeSidebar: () => void;
}

export default function HeaderSection({ closeSidebar }: IProps) {
    return (
        <>
            <Typography variant="h6">
                <strong>{constants.ENTE}</strong>
            </Typography>
            <IconButton
                aria-label="close"
                onClick={closeSidebar}
                sx={{
                    position: 'absolute',
                    right: 16,
                    top: 16,
                    color: (theme) => theme.palette.grey[400],
                }}>
                <CloseIcon />
            </IconButton>
        </>
    );
}
