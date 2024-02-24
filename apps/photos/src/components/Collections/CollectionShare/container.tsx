import { Dialog, styled } from "@mui/material";
import PropTypes from "prop-types";

export const CollectionShareContainer = styled(Dialog)(({ theme }) => ({
    "& .MuiDialog-container": {
        justifyContent: "flex-end",
    },
    "& .MuiPaper-root": {
        width: "414px",
    },
    "& .MuiDialog-paperFullScreen": {
        maxWidth: "100%",
    },
    "& .MuiDialogTitle-root": {
        padding: theme.spacing(4, 3, 3, 4),
    },
    "& .MuiDialogContent-root": {
        padding: theme.spacing(3, 4),
    },
}));

CollectionShareContainer.propTypes = {
    children: PropTypes.node,
    onClose: PropTypes.func.isRequired,
};
