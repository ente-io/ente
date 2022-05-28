import styled from 'styled-components';

const NavbarBase = styled.div`
    width: 100%;
    padding: 0 20px;
    font-size: 20px;
    line-height: 2rem;
    background-color: #111;
    color: #fff;
    min-height: 64px;
    display: flex;
    align-items: center;
    box-shadow: 0 0 5px rgba(0, 0, 0, 0.7);
    position: sticky;
    top: 0;
    z-index: 1;
`;

export default NavbarBase;
