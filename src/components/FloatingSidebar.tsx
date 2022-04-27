import { Dialog, Slide, styled } from '@mui/material';
import React from 'react';
import PropTypes from 'prop-types';

export const FloatingSidebar = styled(Dialog)<{ position: 'left' | 'right' }>(
    ({ position, theme }) => ({
        '& .MuiDialogContent-root': {
            padding: theme.spacing(2),
        },
        '& .MuiDialogActions-root': {
            padding: theme.spacing(1),
        },
        '& .MuiPaper-root': {
            maxWidth: '510px',
        },
        '& .MuiDialog-container': {
            justifyContent: position === 'left' ? 'flex-start' : 'flex-end',
        },
    })
);

FloatingSidebar.propTypes = {
    children: PropTypes.node,
    onClose: PropTypes.func.isRequired,
};

export const Transition = (direction: 'left' | 'right' | 'up') =>
    React.forwardRef(
        (props: { children: React.ReactElement<any, any> }, ref) => {
            return <Slide direction={direction} ref={ref} {...props} />;
        }
    );
