import React from 'react';
import { Button } from 'react-bootstrap';
import styled from 'styled-components';

const Wrapper = styled.div`
    position: fixed;
    display: flex;
    align-items: center;
    justify-content: center;
    top: 0;
    z-index: 100;
    min-height: 64px;
    right: 32px;
    transition: opacity 1s ease;
    cursor: pointer;
`;

function OpenInEnte({ redirect }) {
    return (
        <Wrapper onClick={redirect}>
            <Button variant="outline-success">open in ente</Button>
        </Wrapper>
    );
}

export default OpenInEnte;
