import { Drawer } from '@mui/material';
import styled from 'styled-components';

export const EnteDrawer = styled(Drawer)(({ theme }) => ({
    '& .MuiPaper-root': {
        maxWidth: '375px',
        width: '100%',
        scrollbarWidth: 'thin',
        padding: theme.spacing(1),
    },
}));
