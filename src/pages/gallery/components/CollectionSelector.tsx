import React, { useEffect, useState } from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import { getActualKey } from 'utils/common/key';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import CollectionDropZone from './CollectionDropZone';
import AddCollection from './AddCollection';
import PreviewCard from './PreviewCard';

function CollectionSelector(props) {
    const {
        uploadModalView,
        closeUploadModal,
        collectionLatestFile,
        ...rest
    } = props;

    const [token, setToken] = useState(null);
    const [userMasterKey, setUserMasterKey] = useState(null);

    useEffect(() => {
        (async () => {
            setToken(getData(LS_KEYS.USER).token);
            setUserMasterKey(await getActualKey());
        })();
    });

    const CollectionIcons = collectionLatestFile?.map((item) => (
        <CollectionDropZone
            {...rest}
            closeModal={closeUploadModal}
            collectionLatestFile={item}
            token={token}
        >
            <Card style={{ cursor: 'pointer', border: 'solid', width: "95%", marginBottom: "5px", padding: "auto" }}>
                <Card.Body>
                    <PreviewCard data={item.file} updateUrl={() => { }} onClick={() => { }} />

                    <Card.Text>{item.collection.name}</Card.Text>
                </Card.Body>
            </Card>
        </CollectionDropZone>
    ));

    return (
        <>
            <Modal
                show={uploadModalView}
                centered
                onHide={closeUploadModal}
            >
                <Modal.Header closeButton>
                    <Modal.Title >
                        Select/Click on Collection to upload
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap" }}>
                    <AddCollection
                        {...rest}
                        closeModal={closeUploadModal}
                        token={token}
                        userMasterKey={userMasterKey}
                    >
                        <Card style={{ cursor: 'pointer', border: 'solid', width: "95%", marginBottom: "5px", padding: "auto" }}>
                            <Card.Body>
                                <Card.Text>Create New Album</Card.Text>
                            </Card.Body>
                        </Card>
                    </AddCollection>
                    {CollectionIcons}
                </Modal.Body>
                <Modal.Footer>
                    <Button onClick={closeUploadModal}>Close</Button>
                </Modal.Footer>
            </Modal>
        </>
    );
}

export default CollectionSelector;
