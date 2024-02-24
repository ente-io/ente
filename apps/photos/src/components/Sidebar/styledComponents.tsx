import CircleIcon from "@mui/icons-material/Circle";
import { styled } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";

export const DrawerSidebar = styled(EnteDrawer)(({ theme }) => ({
    "& .MuiPaper-root": {
        padding: theme.spacing(1.5),
    },
}));

DrawerSidebar.defaultProps = { anchor: "left" };

export const DotSeparator = styled(CircleIcon)`
    font-size: 4px;
    margin: 0 ${({ theme }) => theme.spacing(1)};
    color: inherit;
`;
