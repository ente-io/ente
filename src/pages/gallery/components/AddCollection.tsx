import React, { useState } from "react";
import { Card } from "react-bootstrap";
import Dropzone from "react-dropzone";
import styled from "styled-components";
import { DropDiv } from "./CollectionDropZone";
import CreateCollection from "./CreateCollection";

const ImageContainer = styled.div`
    min-height: 192px;
    max-width: 192px;
    border: 1px solid #555;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 42px;
`;

const StyledCard = styled(Card)`
    cursor: pointer;
`;

export default function AddCollection(props) {

    const [acceptedFiles, setAcceptedFiles] = useState<File[]>();
    const [createCollectionView, setCreateCollectionView] = useState(false);

    const { children, closeUploadModal, showUploadModal, ...rest } = props;

    const createCollection = (acceptedFiles) => {
        setAcceptedFiles(acceptedFiles);
        setCreateCollectionView(true);
    };

    return (
        <>
            <Dropzone
                onDropAccepted={createCollection}
                onDropRejected={closeUploadModal}
                onDragOver={showUploadModal}
                noDragEventsBubbling
                accept="image/*, video/*"
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
                            <StyledCard>
                                <ImageContainer>+</ImageContainer>
                                <Card.Text style={{ textAlign: "center" }}>Create New Album</Card.Text>
                            </StyledCard>
                        </DropDiv>
                    );
                }}
            </Dropzone>
            <CreateCollection
                {...rest}
                modalView={createCollectionView}
                closeUploadModal={closeUploadModal}
                closeModal={() => setCreateCollectionView(false)}
                acceptedFiles={acceptedFiles}
            />
        </>
    )
}
