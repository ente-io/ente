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

export default function FullScreenDropZone({
    children,
    showModal,
    closeModal,
}: Props) {
    const closeTimer = useRef<NodeJS.Timeout>();

    const clearTimer = () => {
        if (closeTimer.current) {
            clearTimeout(closeTimer.current);
        }
    };

    const onDragOver = (e) => {
        e.preventDefault();
        clearTimer();
        showModal();
    };

    const onDragLeave = (e) => {
        e.preventDefault();
        clearTimer();
        closeTimer.current = global.setTimeout(closeModal, 1000);
    };

    return (
        <DropDiv onDragOver={onDragOver} onDragLeave={onDragLeave}>
            {children}
        </DropDiv>
    );
}
