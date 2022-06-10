import { FlexWrapper } from 'components/Container';
import styled from 'styled-components';

const NavbarBase = styled(FlexWrapper)`
    padding: 0 20px;
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 1;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
`;

export default NavbarBase;
