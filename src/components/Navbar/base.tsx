import { FlexWrapper } from 'components/Container';
import { styled } from '@mui/material';
import { SpecialPadding } from 'styles/SpecialPadding';
const NavbarBase = styled(FlexWrapper)`
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 1;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
    background-color: ${({ theme }) => theme.palette.background.default};
    margin-bottom: 16px;
    ${SpecialPadding}
`;

export default NavbarBase;
