import { Dialog, Slide, styled } from '@mui/material';
import React from 'react';
import PropTypes from 'prop-types';

export const AllCollectionContainer = styled(Dialog)(({ theme }) => ({
    '& .MuiDialog-container': {
        justifyContent: 'flex-end',
    },
    '& .MuiPaper-root': {
        maxWidth: '498px',
    },
    '& .MuiDialogTitle-root': {
        padding: theme.spacing(3, 2),
    },
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2),
    },
}));

AllCollectionContainer.propTypes = {
    children: PropTypes.node,
    onClose: PropTypes.func.isRequired,
};

export const Transition = (direction: 'left' | 'right' | 'up') =>
    React.forwardRef(
        (props: { children: React.ReactElement<any, any> }, ref) => {
            return <Slide direction={direction} ref={ref} {...props} />;
        }
    );
