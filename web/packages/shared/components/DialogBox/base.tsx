import { Dialog, styled } from "@mui/material";

const DialogBoxBase = styled(Dialog)(({ theme }) => ({
    "& .MuiDialog-paper": {
        padding: theme.spacing(1, 1.5),
        maxWidth: "346px",
    },

    "& .DialogIcon": {
        padding: theme.spacing(2),
        paddingBottom: theme.spacing(1),
    },

    "& .MuiDialogTitle-root": {
        padding: theme.spacing(2),
        paddingBottom: theme.spacing(1),
    },
    "& .MuiDialogContent-root": {
        padding: theme.spacing(2),
    },

    ".DialogIcon + .MuiDialogTitle-root": {
        paddingTop: 0,
    },

    ".MuiDialogTitle-root + .MuiDialogContent-root": {
        paddingTop: 0,
    },
    ".MuiDialogTitle-root + .MuiDialogActions-root": {
        paddingTop: theme.spacing(3),
    },
    "& .MuiDialogActions-root": {
        flexWrap: "wrap-reverse",
    },
    "& .MuiButton-root": {
        margin: `${theme.spacing(0.5, 0)} !important`,
    },
}));

export default DialogBoxBase;
