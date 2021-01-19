import React from 'react';
import styled from 'styled-components';

const DropDiv = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
`;

const FullScreenDropZone = ({
    children,
    closeModal,
    showModal,
}) =>
(
    <DropDiv onDragOver={(ev) => {
        ev.preventDefault();
        showModal();
    }} onDragLeave={(ev) => {
        ev.preventDefault();
        closeModal();
    }}>
        {children}
    </DropDiv>
);

export default FullScreenDropZone;
