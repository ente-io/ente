import React, { useState } from "react";
import { Card } from "react-bootstrap";
import Dropzone from "react-dropzone";
import styled from "styled-components";
import { DropDiv } from "./CollectionDropZone";
import CreateCollection from "./CreateCollection";

const Image = styled.img`
  max-height: 190px;
`;

export default function AddCollection(props) {

    const [acceptedFiles, setAcceptedFiles] = useState<File[]>();
    const [createCollectionView, setCreateCollectionView] = useState(false);

    const { children, closeUploadModal, ...rest } = props;

    const createCollection = (acceptedFiles) => {
        setAcceptedFiles(acceptedFiles);
        setCreateCollectionView(true);
    };

    return (
        <>
            <Dropzone
                onDropAccepted={createCollection}
                onDropRejected={closeUploadModal}
                noDragEventsBubbling
                accept="image/*, video/*, application/json "
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
                            <Card style={{ cursor: 'pointer' }}>
                                <Image alt='logo' src='/plus-sign.png' />
                                <Card.Text style={{ textAlign: "center" }}>Create New Album</Card.Text>
                            </Card>
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
