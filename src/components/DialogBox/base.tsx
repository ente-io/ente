import { Dialog, styled } from '@mui/material';

const DialogBoxBase = styled(Dialog)(({ theme, maxWidth }) => ({
    '& .MuiDialog-paper': {
        padding: theme.spacing(1, 1.5),
        maxWidth: maxWidth ?? '346px',
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
    '.MuiDialogTitle-root + .MuiDialogActions-root': {
        paddingTop: theme.spacing(3),
    },
}));

export default DialogBoxBase;
