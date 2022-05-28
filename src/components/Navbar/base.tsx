import { FlexWrapper } from 'components/Container';
import styled from 'styled-components';

const NavbarBase = styled(FlexWrapper)`
    width: 100%;
    padding: 0 20px;
    background-color: #111;
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 1;
`;

export default NavbarBase;
