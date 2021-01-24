import React, { useRef } from 'react';
import styled from 'styled-components';

const DropDiv = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
`;

type Props = React.PropsWithChildren<{
    showModal: () => void;
    closeModal: () => void;
}>;

export default function FullScreenDropZone({ children, showModal, closeModal }: Props) {
    const closeTimer = useRef<number>();
    return (
        <DropDiv onDragOver={(ev) => {
            // ev.preventDefault();
            if (closeTimer.current) {
                clearTimeout(closeTimer.current);
            }
            showModal();
        }} onDragLeave={(ev) => {
            // ev.preventDefault();
            closeTimer.current = setTimeout(closeModal, 300);
        }}>
            {children}
        </DropDiv>
    );
};
