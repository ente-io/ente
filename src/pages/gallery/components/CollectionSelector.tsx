import React from 'react';
import { Card, Modal } from 'react-bootstrap';
import AddCollectionButton from './AddCollectionButton';
import PreviewCard from './PreviewCard';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import EnteSpinner from 'components/EnteSpinner';

export const CollectionIcon = styled.div`
    width: 200px;
    margin: 10px;
    height: 240px;
    padding: 4px;
    color: black;
    border-width: 4px;
    border-radius: 34px;
    outline: none;
`;

export const LoadingOverlay = styled.div`
    left: 0;
    top: 0;
    outline: none;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-weight: 900;
    position: absolute;
    background: rgba(0, 0, 0, 0.5);
    z-index: 9000;
`;
interface Props {
    collectionAndItsLatestFile;
    uploadFiles;
    collectionSelectorView;
    closeCollectionSelector;
    showNextModal;
    loading;
}
function CollectionSelector(props: Props) {
    const CollectionIcons: JSX.Element[] = props.collectionAndItsLatestFile?.map(
        (item) => (
            <CollectionIcon
                key={item.collection.id}
                onClick={async () => await props.uploadFiles(item.collection)}
            >
                <Card>
                    <PreviewCard
                        data={item.file}
                        updateUrl={() => {}}
                        forcedEnable
                    />
                    <Card.Text className="text-center">
                        {item.collection.name}
                    </Card.Text>
                </Card>
            </CollectionIcon>
        )
    );

    return (
        <Modal
            show={props.collectionSelectorView}
            onHide={props.closeCollectionSelector}
            dialogClassName="modal-90w"
            style={{ maxWidth: '100%' }}
        >
            <Modal.Header closeButton>
                <Modal.Title>{constants.SELECT_COLLECTION}</Modal.Title>
            </Modal.Header>
            <Modal.Body
                style={{
                    display: 'flex',
                    justifyContent: 'flex-start',
                    flexWrap: 'wrap',
                }}
            >
                <AddCollectionButton showChoiceModal={props.showNextModal} />
                {CollectionIcons}
                {props.loading && (
                    <LoadingOverlay>
                        <EnteSpinner />
                    </LoadingOverlay>
                )}
            </Modal.Body>
        </Modal>
    );
}

export default CollectionSelector;
