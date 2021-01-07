import React from 'react';
import Dropzone from 'react-dropzone';
import styled from 'styled-components';

const DropDiv = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
`;

const FullScreenDropZone = ({
  children,
  noClick,
  closeModal,
  showModal,
}) => {
  return (
    <>
      <Dropzone
        noClick={noClick}
        onDragOver={showModal}
        onDragLeave={closeModal}
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

export default FullScreenDropZone;
