import React from 'react';
import Dropzone from 'react-dropzone';
import styled from 'styled-components';
import UploadService from 'services/uploadService';
import { getToken } from 'utils/common/key';

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

export const enableBorder = (props) => (props.isDragActive ? 'dashed' : 'none');

export const DropDiv = styled.div`
  width:200px;
  margin:5px;
  height:230px;
  color:black;
  border-width: 2px;
  border-radius: 2px;
  border-color: ${(props) => getColor(props)};
  border-style: ${(props) => enableBorder(props)};
  outline: none;
  transition: border 0.24s ease-in-out;
`;

function CollectionDropZone(props) {
    const { children,
        closeModal,
        showModal,
        refetchData,
        collectionLatestFile,
        setProgressView,
        progressBarProps, setErrorCode } = props
    const upload = async (acceptedFiles) => {
        try {
            const token = getToken();
            closeModal();
            progressBarProps.setPercentComplete(0);
            setProgressView(true);

            await UploadService.uploadFiles(acceptedFiles, collectionLatestFile, token, progressBarProps);
            refetchData();
        } catch (err) {
            if (err.response)
                setErrorCode(err.response.status);
        }
        finally {
            setProgressView(false);
        }
    }
    return (
        <Dropzone
            onDropAccepted={upload}
            onDragOver={showModal}
            onDropRejected={closeModal}
            noDragEventsBubbling
            accept="image/*, video/*, application/json, "
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
