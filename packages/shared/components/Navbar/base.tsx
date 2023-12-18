import { FlexWrapper } from '../../components/Container';
import { styled } from '@mui/material';
const NavbarBase = styled(FlexWrapper)<{ isMobile: boolean }>`
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 10;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
    background-color: ${({ theme }) => theme.colors.background.base};
    margin-bottom: 16px;
    padding: 0 24px;
    @media (max-width: 720px) {
        padding: 0 4px;
    }
`;

export default NavbarBase;
