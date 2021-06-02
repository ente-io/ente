import React, { useEffect } from 'react';
import { Card, Modal } from 'react-bootstrap';
import styled from 'styled-components';
import { CollectionAndItsLatestFile } from 'services/collectionService';
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
    callback: (collection) => void;
    showNextModal: () => void;
    title: string;
}
export type SetCollectionSelectorAttributes = React.Dispatch<
    React.SetStateAction<CollectionSelectorAttributes>
>;

interface Props {
    show: boolean;
    onHide: () => void;
    setLoading: (value: boolean) => void;
    directlyShowNextModal: boolean;
    collectionsAndTheirLatestFile: CollectionAndItsLatestFile[];
    attributes: CollectionSelectorAttributes;
}
function CollectionSelector({
    attributes,
    directlyShowNextModal,
    collectionsAndTheirLatestFile,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    setLoading,
    ...props
}: Props) {
    useEffect(() => {
        // setLoading(false);
        if (directlyShowNextModal && attributes) {
            props.onHide();
            attributes.showNextModal();
        }
    }, [attributes]);
    // useEffect(()=>{
    //     if (props.show && !attributes) {
    //         setLoading(true);
    //     }
    // }, [props.show]);

    if (!attributes) {
        return <Modal />;
    }
    const CollectionIcons: JSX.Element[] = collectionsAndTheirLatestFile?.map(
        (item) => (
            <CollectionIcon
                key={item.collection.id}
                onClick={() => {
                    attributes.callback(item.collection);
                    props.onHide();
                }}
            >
                <Card>
                    <PreviewCard
                        file={item.file}
                        updateUrl={() => { }}
                        forcedEnable
                    />
                    <Card.Text className="text-center">
                        {item.collection.name}
                    </Card.Text>
                </Card>
            </CollectionIcon>
        ),
    );

    return (
        <Modal {...props} size="xl" centered>
            <Modal.Header closeButton>
                <Modal.Title>{attributes.title}</Modal.Title>
            </Modal.Header>
            <Modal.Body
                style={{
                    display: 'flex',
                    justifyContent: 'space-around',
                    flexWrap: 'wrap',
                }}
            >
                <AddCollectionButton showNextModal={attributes.showNextModal} />
                {CollectionIcons}
            </Modal.Body>
        </Modal>
    );
}

export default CollectionSelector;
