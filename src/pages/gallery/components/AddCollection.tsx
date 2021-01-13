import React, { useState } from "react";
import Dropzone from "react-dropzone";
import { DropDiv } from "./CollectionDropZone";
import CreateCollection from "./CreateCollection";

export default function AddCollection(props) {

    const [acceptedFiles, setAcceptedFiles] = useState<File[]>();
    const [createCollectionView, setCreateCollectionView] = useState(false);

    const { children, closeModal, ...rest } = props;

    const createCollection = (acceptedFiles) => {
        closeModal();
        setAcceptedFiles(acceptedFiles);
        setCreateCollectionView(true);
    };

    return (
        <>
            <Dropzone
                onDropAccepted={createCollection}
                onDropRejected={props.closeUploadModal}
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
                            {children}
                        </DropDiv>
                    );
                }}
            </Dropzone>
            <CreateCollection
                {...rest}
                show={createCollectionView}
                closeModal={() => setCreateCollectionView(false)}
                acceptedFiles={acceptedFiles}
            />
        </>
    )
}
