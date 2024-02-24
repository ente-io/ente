import { Drawer, styled } from "@mui/material";

export const EnteDrawer = styled(Drawer)(({ theme }) => ({
    "& .MuiPaper-root": {
        maxWidth: "375px",
        width: "100%",
        scrollbarWidth: "thin",
        padding: theme.spacing(1),
    },
}));
