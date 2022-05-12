import { Drawer, Divider, styled } from '@mui/material';
import { default as MuiStyled } from '@mui/styled-engine';
import CircleIcon from '@mui/icons-material/Circle';

export const DrawerSidebar = MuiStyled(Drawer)(({ theme }) => ({
    '& .MuiPaper-root': {
        width: '320px',
        padding: theme.spacing(2, 1, 4, 1),
    },
}));

DrawerSidebar.defaultProps = { anchor: 'left' };

export const PaddedDivider = MuiStyled(Divider)<{
    invisible?: boolean;
    dense?: boolean;
}>(({ theme, invisible, dense }) => ({
    margin: theme.spacing(dense ? 1 : 2, 0),
    opacity: invisible ? 0 : 1,
}));

export const DotSeparator = styled(CircleIcon)`
    height: 4px;
    width: 4px;
    left: 86px;
    top: 18px;
    border-radius: 0px;
    margin: 0 ${({ theme }) => theme.spacing(1)};
    color: ${({ theme }) => theme.palette.text.secondary};
`;
