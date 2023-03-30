import { styled, Theme } from '@mui/material';
import CircleIcon from '@mui/icons-material/Circle';
import { EnteDrawer } from 'components/EnteDrawer';

export const DrawerSidebar = styled(EnteDrawer)(
    ({ theme }: { theme: Theme }) => ({
        '& .MuiPaper-root': {
            padding: theme.spacing(1.5),
        },
    })
);

DrawerSidebar.defaultProps = { anchor: 'left' };

export const DotSeparator = styled(CircleIcon)`
    font-size: 4px;
    margin: 0 ${({ theme }: { theme: Theme }) => theme.spacing(1)};
    color: inherit;
`;
