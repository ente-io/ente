import { Dialog } from '@mui/material';
import styled from 'styled-components';

const MessageDialogBase = styled(Dialog)(({ theme }) => ({
    '& .MuiPaper-root': {
        padding: theme.spacing(4, 3),
    },
    '& .MuiDialogTitle-root': {
        padding: 0,
        paddingBottom: theme.spacing(2),
        [theme.breakpoints.down('sm')]: {
            paddingBottom: '12px',
        },
    },
    '& .MuiDialogContent-root': {
        padding: 0,
        paddingBottom: theme.spacing(8),
        [theme.breakpoints.down('sm')]: {
            paddingBottom: '48px',
        },
    },
    '& .MuiDialogActions-root': {
        padding: 0,
    },
    '& .MuiDialogActions-root .MuiButton-root': {
        [theme.breakpoints.down('sm')]: {
            fontSize: '12px',
        },
    },
}));

export default MessageDialogBase;
