import { Dialog, styled } from '@mui/material';

const DialogBoxBase = styled(Dialog)(({ theme }) => ({
    '& .MuiDialog-paper': {
        padding: 0,
    },
    '& .MuiDialogTitle-root': {
        padding: theme.spacing(2),
        paddingBottom: theme.spacing(1),
    },
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2),
    },
    '.MuiDialogTitle-root + .MuiDialogContent-root': {
        paddingTop: 0,
    },
}));

export default DialogBoxBase;
