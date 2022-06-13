import styled from 'styled-components';

export const LoadingOverlay = styled.div`
    left: 0;
    top: 0;
    outline: none;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-weight: 900;
    position: absolute;
    background: rgba(0, 0, 0, 0.5);
    z-index: 9000;
`;
