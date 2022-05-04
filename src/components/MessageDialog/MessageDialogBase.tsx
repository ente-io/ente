import { Dialog } from '@mui/material';
import styled from 'styled-components';

const MessageDialogBase = styled(Dialog)(({ theme }) => ({
    '& .MuiPaper-root': {
        padding: theme.spacing(4, 3),
    },
    '& .MuiDialogTitle-root': {
        padding: 0,
        ...theme.typography.h5,
        fontWeight: 600,
    },
    '& .MuiDialogContent-root': {
        padding: 0,
        paddingTop: theme.spacing(2),
        [theme.breakpoints.down('sm')]: {
            paddingTop: '12px',
        },
    },
    '& .MuiDialogActions-root': {
        padding: 0,
        paddingTop: theme.spacing(8),
        [theme.breakpoints.down('sm')]: {
            paddingTop: '48px',
        },
    },
    '& .MuiDialogActions-root .MuiButton-root': {
        marginLeft: theme.spacing(3),
        [theme.breakpoints.down('sm')]: {
            fontSize: '14px',
            marginLeft: theme.spacing(2),
        },
    },
}));

export default MessageDialogBase;
