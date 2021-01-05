import React from 'react';
import Dropzone from 'react-dropzone';
import styled from 'styled-components';

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
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  border-width: 2px;
  border-radius: 2px;
  border-color: ${(props) => getColor(props)};
  border-style: ${(props) => enableBorder(props)};
  outline: none;
  transition: border 0.24s ease-in-out;
`;

const FileUpload = ({
  children,
  noClick = null,
  closeModal = null,
  showModal = null,
  collectionLatestFile = null,
  noDragEventsBubbling = null,
}) => {
  return (
    <>
      <Dropzone
        onDrop={(acceptedFiles) => {
          console.log(collectionLatestFile.collectionName);
          closeModal();
        }}
        noClick={noClick}
        onDragOver={showModal}
        onDragLeave={closeModal}
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
            <>
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
            </>
          );
        }}
      </Dropzone>
    </>
  );
};

export default FileUpload;
