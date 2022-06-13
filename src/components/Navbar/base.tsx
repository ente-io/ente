import { FlexWrapper } from 'components/Container';
import { styled } from '@mui/material';
const NavbarBase = styled(FlexWrapper)`
    padding: 0 20px;
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 1;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
    background-color: ${({ theme }) => theme.palette.background.default};
`;

export default NavbarBase;
