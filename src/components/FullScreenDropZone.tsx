import React, { useRef } from 'react';
import styled from 'styled-components';

export const getColor = (props) => {
    if (props.isDragAccept) {
        return '#00e676';
    }
    if (props.isDragReject) {
        return '#ff1744';
    }
    if (props.isDragActive) {
        return '#2196f3';
    }
};

export const enableBorder = (props) => (props.isDragActive ? 'solid' : 'none');
const DropDiv = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
    color: black;
    border-width: 4px;
    border-radius: 34px;
    border-color: ${(props) => getColor(props)};
    border-style: ${(props) => enableBorder(props)};
    outline: none;
    transition: border 0.24s ease-in-out;
`;

type Props = React.PropsWithChildren<{
    getRootProps: any;
    getInputProps: any;
    isDragActive;
    isDragAccept;
    isDragReject;
}>;

export default function FullScreenDropZone(props: Props) {
    const { isDragActive, isDragAccept, isDragReject } = props;
    return (
        <DropDiv
            {...props.getRootProps({
                className: 'dropzone',
                isDragActive,
                isDragAccept,
                isDragReject,
            })}
        >
            <input {...props.getInputProps()} />
            {props.children}
        </DropDiv>
    );
}
