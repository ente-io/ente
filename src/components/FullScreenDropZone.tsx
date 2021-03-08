import React, { useRef } from 'react';
import styled from 'styled-components';

const DropDiv = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
`;

type Props = React.PropsWithChildren<{
    showModal: () => void;
}>;

export default function FullScreenDropZone({
    children,
    showModal,
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

    return (
        <DropDiv onDragOver={onDragOver}>
            {children}
        </DropDiv>
    );
}
