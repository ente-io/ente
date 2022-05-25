import { Dialog, styled } from '@mui/material';

const DialogBoxBase = styled(Dialog)(({ theme }) => ({
    '& .MuiDialogTitle-root': {
        padding: theme.spacing(4, 3, 2),
    },
    '& .MuiDialogContent-root': {
        padding: theme.spacing(0, 3, 2),
    },
    '& .MuiDialogActions-root': {
        padding: theme.spacing(4, 3),
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
