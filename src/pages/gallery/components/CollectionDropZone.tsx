import React from 'react';
import Dropzone from 'react-dropzone';
import styled from 'styled-components';
import { uploadFiles } from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';

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
  collectionLatestFile,
  noDragEventsBubbling,
  showProgress,
}) => {
  return (
    <Dropzone
      onDrop={async (acceptedFiles) => {
        closeModal();
        showProgress();
        await uploadFiles(acceptedFiles, collectionLatestFile);
      }}
      noDragEventsBubbling={noDragEventsBubbling}
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
