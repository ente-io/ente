import React from 'react';
import Dropzone from 'react-dropzone';
import styled from 'styled-components';
import UploadService from 'services/uploadService';
import { fetchData } from 'services/fileService';

const getColor = (props) => {
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

const enableBorder = (props) => (props.isDragActive ? 'dashed' : 'none');

const DropDiv = styled.div`
  width:33%;
  border-width: 2px;
  border-radius: 2px;
  border-color: ${(props) => getColor(props)};
  border-style: ${(props) => enableBorder(props)};
  outline: none;
  transition: border 0.24s ease-in-out;
`;

const CollectionDropZone = ({
    children,
    closeModal,
    setData,
    collectionLatestFile,
    noDragEventsBubbling,
    setProgressView,
    token,
    encryptionKey,
    progressBarProps

}) => {

    const upload = async (acceptedFiles) => {
        closeModal();
        setProgressView(true);
        await UploadService.uploadFiles(acceptedFiles, collectionLatestFile, token, progressBarProps);
        setProgressView(false);
        setData(await fetchData(token, encryptionKey, [collectionLatestFile.collection]));
    }
    return (
        <Dropzone
            onDropAccepted={upload}
            onDropRejected={closeModal}
            noDragEventsBubbling={noDragEventsBubbling}
            accept="image/*, video/* "
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
};

export default CollectionDropZone;
