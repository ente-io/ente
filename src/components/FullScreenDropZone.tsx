import React from 'react';
import styled from 'styled-components';

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

const Overlay = styled.div`
    border-width: 4px;
    border-radius: 34px;
    outline: none;
    transition: border 0.24s ease-in-out;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    text-align: center;
    position: absolute;
    border-color: ${(props) => getColor(props)};
    border-style: solid;
    background: rgba(0, 0, 0, 0.5);
    z-index: 9;
`;

type Props = React.PropsWithChildren<{
    getRootProps: any;
    getInputProps: any;
    isDragActive;
    onDragLeave;
    onDragEnter;
}>;

export default function FullScreenDropZone(props: Props) {
    return (
        <DropDiv {...props.getRootProps()} onDragEnter={props.onDragEnter}>
            <input {...props.getInputProps()} />
            {props.isDragActive && (
                <Overlay
                    onDragLeave={props.onDragLeave}
                    isDragActive={props.isDragActive}
                >
                    drop to backup your files
                </Overlay>
            )}
            {props.children}
        </DropDiv>
    );
}
