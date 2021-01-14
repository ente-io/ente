import React, { useState } from "react";
import { Card } from "react-bootstrap";
import Dropzone from "react-dropzone";
import { DropDiv } from "./CollectionDropZone";
import CreateCollection from "./CreateCollection";

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
                            <Card style={{ cursor: 'pointer', border: 'solid', width: "95%", marginBottom: "5px", padding: "auto" }}>
                                <Card.Body>
                                    <Card.Text>Create New Album</Card.Text>
                                </Card.Body>
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
