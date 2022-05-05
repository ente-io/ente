import { Dialog, DialogProps } from '@mui/material';
import { FC } from 'react';
import React from 'react';
import styled from 'styled-components';

const StyledMessageDialog = styled(Dialog)(({ theme }) => ({
    '& .MuiPaper-root': {
        padding: '32px 32px 32px 28px',
        margin: '16px',
    },
    '& .MuiDialogTitle-root': {
        padding: 0,
        fontSize: '30px',
        fontWeight: 600,
        lineHeight: '36.31px',
    },
    '& .MuiDialogContent-root': {
        padding: 0,
        fontSize: '18px',
        lineHeight: '21.78px',
        paddingTop: theme.spacing(2),
        [theme.breakpoints.down('sm')]: {
            paddingTop: '12px',
        },
    },

    '& .MuiDialogContent-root > *': {
        fontSize: '18px',
        color: theme.palette.text.secondary,
    },
    '& .MuiDialogActions-root': {
        padding: 0,
        paddingTop: theme.spacing(8),
        [theme.breakpoints.down('sm')]: {
            paddingTop: '48px',
        },
    },
    '& .MuiDialogActions-root .MuiButton-root': {
        fontSize: '18px',
        lineHeight: '21.78px',
        padding: theme.spacing(2),
        marginLeft: theme.spacing(2),
    },
}));

interface MessageDialogBaseProps extends DialogProps {
    staticBackDrop?: boolean;
}

const MessageDialogBase: FC<MessageDialogBaseProps> = ({
    children,
    staticBackDrop,
    ...props
}) => {
    const handleClose: DialogProps['onClose'] = (_, reason) => {
        if (staticBackDrop && reason === 'backdropClick') {
            // no-op
        } else {
            props.onClose;
        }
    };
    return (
        <StyledMessageDialog onClose={handleClose} {...props}>
            {children}
        </StyledMessageDialog>
    );
};

export default MessageDialogBase;
