import { Drawer, styled, Theme } from '@mui/material';

export const EnteDrawer = styled(Drawer)(({ theme }: { theme: Theme }) => ({
    '& .MuiPaper-root': {
        maxWidth: '375px',
        width: '100%',
        scrollbarWidth: 'thin',
        padding: theme.spacing(1),
    },
}));
