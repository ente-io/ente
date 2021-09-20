import React, { useEffect } from 'react';
import { Card, Modal } from 'react-bootstrap';
import styled from 'styled-components';
import {
    Collection,
    CollectionAndItsLatestFile,
} from 'services/collectionService';
import AddCollectionButton from './AddCollectionButton';
import PreviewCard from './PreviewCard';

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

export interface CollectionSelectorAttributes {
    callback: (collection: Collection) => void;
    showNextModal: () => void;
    title: string;
    fromCollection?: number;
}
export type SetCollectionSelectorAttributes = React.Dispatch<
    React.SetStateAction<CollectionSelectorAttributes>
>;

const CollectionCard = styled(Card)`
    display: flex;
    flex-direction: column;
    height: 221px;
`;

interface Props {
    show: boolean;
    onHide: (closeBtnClick?: boolean) => void;
    collectionsAndTheirLatestFile: CollectionAndItsLatestFile[];
    attributes: CollectionSelectorAttributes;
}
function CollectionSelector({
    attributes,
    collectionsAndTheirLatestFile,
    ...props
}: Props) {
    useEffect(() => {
        if (!attributes) {
            return;
        }
        const collectionOtherThanFrom = collectionsAndTheirLatestFile?.filter(
            (item) => !(item.collection.id === attributes.fromCollection)
        );
        if (collectionOtherThanFrom.length === 0) {
            props.onHide();
            attributes.showNextModal();
        }
    }, [props.show]);

    if (!attributes) {
        return <Modal />;
    }
    const CollectionIcons: JSX.Element[] = collectionsAndTheirLatestFile
        ?.filter((item) => !(item.collection.id === attributes.fromCollection))
        .map((item) => (
            <CollectionIcon
                key={item.collection.id}
                onClick={() => {
                    attributes.callback(item.collection);
                    props.onHide();
                }}>
                <CollectionCard>
                    <PreviewCard
                        file={item.file}
                        updateUrl={() => {}}
                        forcedEnable
                    />
                    <Card.Text className="text-center">
                        {item.collection.name}
                    </Card.Text>
                </CollectionCard>
            </CollectionIcon>
        ));

    return (
        <Modal
            {...props}
            size="xl"
            centered
            contentClassName="plan-selector-modal-content">
            <Modal.Header closeButton onHide={() => props.onHide(true)}>
                <Modal.Title>{attributes.title}</Modal.Title>
            </Modal.Header>
            <Modal.Body
                style={{
                    display: 'flex',
                    justifyContent: 'space-around',
                    flexWrap: 'wrap',
                }}>
                <AddCollectionButton showNextModal={attributes.showNextModal} />
                {CollectionIcons}
            </Modal.Body>
        </Modal>
    );
}

export default CollectionSelector;
