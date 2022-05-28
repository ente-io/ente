import Navbar from 'components/Navbar/base';
import styled from 'styled-components';

export const SelectionBar = styled(Navbar)`
    position: fixed;
    top: 0;
    color: #fff;
    z-index: 1001;
    width: 100%;
    padding: 0 16px;
`;

export const SelectionContainer = styled.div`
    flex: 1;
    align-items: center;
    display: flex;
`;
