import React, { useEffect, useState } from 'react';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import CrossIcon from './CrossIcon';

const CloseButtonWrapper = styled.div`
    position: absolute;
    top:10px;
    right:10px;
    cursor:pointer;
`;
const DropDiv = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
`;
const Overlay = styled.div`
    border-width: 8px;
    left: 0;
    top: 0;
    outline: none;
    transition: border 0.24s ease-in-out;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-size: 24px;
    font-weight: 900;
    text-align: center;
    position: absolute;
    border-color: #2dc262;
    border-style: solid;
    background: rgba(0, 0, 0, 0.9);
    z-index: 3000;
`;

type Props = React.PropsWithChildren<{
    getRootProps: any;
    getInputProps: any;
    showCollectionSelector;
}>;

export default function FullScreenDropZone(props: Props) {
    const [isDragActive, setIsDragActive] = useState(false);
    const onDragEnter = () => setIsDragActive(true);
    const onDragLeave = () => setIsDragActive(false);

    useEffect(() => {
        window.addEventListener('keydown', (event) => {
            if (event.code === 'Escape') {
                onDragLeave();
            }
        });
    }, []);
    return (
        <DropDiv
            {...props.getRootProps({
                onDragEnter,
                onDrop: (e) => {
                    e.preventDefault();
                    props.showCollectionSelector();
                },
            })}
        >
            <input {...props.getInputProps()} />
            {isDragActive && (
                <Overlay
                    onDrop={onDragLeave}
                    onDragLeave={onDragLeave}
                >
                    <CloseButtonWrapper onClick={onDragLeave}>
                        <CrossIcon />
                    </CloseButtonWrapper>
                    {constants.UPLOAD_DROPZONE_MESSAGE}
                </Overlay>
            )}
            {props.children}
        </DropDiv>
    );
}
