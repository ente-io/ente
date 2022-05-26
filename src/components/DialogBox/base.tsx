import { Dialog, styled } from '@mui/material';

const DialogBoxBase = styled(Dialog)(({ theme }) => ({
    '& .MuiDialog-paper': {
        padding: theme.spacing(2, 0),
    },
    '& .MuiDialogTitle-root': {
        padding: theme.spacing(2, 3),
    },
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2, 3),
    },
    '& .MuiDialogActions-root': {
        padding: theme.spacing(2, 3),
    },
    '& .MuiDialogActions-root button': {
        fontSize: '18px',
        lineHeight: '21.78px',
        padding: theme.spacing(2),
    },
    '& .MuiDialogActions-root button:not(:first-child)': {
        marginLeft: theme.spacing(2),
    },
}));

DialogBoxBase.defaultProps = {
    fullWidth: true,
    maxWidth: 'sm',
};

export default DialogBoxBase;
