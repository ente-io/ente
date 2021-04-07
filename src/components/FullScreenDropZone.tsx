import React, { useState } from 'react';
import styled from 'styled-components';
import constants from 'utils/strings/constants';

export const getColor = (props) => {
    if (props.isDragActive) {
        return '#00e676';
    } else {
        return '#191919';
    }
};

export const enableBorder = (props) => (props.isDragActive ? 'solid' : 'none');
const DropDiv = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
`;

const Overlay = styled.div<{ isDragActive: boolean }>`
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
    border-color: ${(props) => getColor(props)};
    border-style: solid;
    background: rgba(0, 0, 0, 0.9);
    z-index: 9;
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
                    isDragActive={isDragActive}
                >
                    {constants.UPLOAD_DROPZONE_MESSAGE}
                </Overlay>
            )}
            {props.children}
        </DropDiv>
    );
}
