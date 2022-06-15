import { Drawer, Divider, styled } from '@mui/material';
import CircleIcon from '@mui/icons-material/Circle';

export const DrawerSidebar = styled(Drawer)(({ theme }) => ({
    '& .MuiPaper-root': {
        width: '320px',
        padding: theme.spacing(2, 1, 4, 1),
    },
}));

DrawerSidebar.defaultProps = { anchor: 'left' };

export const PaddedDivider = styled(Divider)<{
    invisible?: boolean;
    spaced?: boolean;
}>(({ theme, invisible, spaced }) => ({
    margin: theme.spacing(spaced ? 2 : 1, 0),
    opacity: invisible ? 0 : 1,
}));

export const DotSeparator = styled(CircleIcon)`
    font-size: 4px;
    margin: 0 ${({ theme }) => theme.spacing(1)};
    color: inherit;
`;
