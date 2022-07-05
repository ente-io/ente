import { Drawer, styled } from '@mui/material';
import CircleIcon from '@mui/icons-material/Circle';

export const DrawerSidebar = styled(Drawer)(({ theme }) => ({
    '& .MuiPaper-root': {
        maxWidth: '375px',
        width: '100%',
        scrollbarWidth: 'thin',
        padding: theme.spacing(1.5),
    },
}));

DrawerSidebar.defaultProps = { anchor: 'left' };

export const DotSeparator = styled(CircleIcon)`
    font-size: 4px;
    margin: 0 ${({ theme }) => theme.spacing(1)};
    color: inherit;
`;
