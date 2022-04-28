import { Drawer, Divider } from '@mui/material';
import { default as MuiStyled } from '@mui/styled-engine';

export const DrawerSidebar = MuiStyled(Drawer)(() => ({
    '& .MuiPaper-root': {
        width: '320px',
        padding: '20px',
    },
}));

export const DividerWithMargin = MuiStyled(Divider)(() => ({
    marginTop: '20px',
    marginBottom: '20px',
}));
