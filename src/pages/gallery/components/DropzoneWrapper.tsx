import React from 'react';
import Dropzone from 'react-dropzone';
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

export const DropDiv = styled.div`
    width: 200px;
    margin: 5px;
    height: 240px;
    padding: 4px;
    color: black;
    border-width: 4px;
    border-radius: 34px;
    border-color: ${(props) => getColor(props)};
    border-style: ${(props) => enableBorder(props)};
    outline: none;
    transition: border 0.24s ease-in-out;
`;

export function DropzoneWrapper(props) {
    const { children, ...callbackProps } = props;
    return (
        <Dropzone
            noDragEventsBubbling
            accept="image/*, video/*, application/json, "
            {...callbackProps}
        >
            {({
                getRootProps,
                getInputProps,
                isDragActive,
                isDragAccept,
                isDragReject,
            }) => {
                return (
                    <DropDiv
                        {...getRootProps({
                            isDragActive,
                            isDragAccept,
                            isDragReject,
                        })}
                    >
                        <input {...getInputProps()} />
                        {children}
                    </DropDiv>
                );
            }}
        </Dropzone>
    );
}

export default DropzoneWrapper;
