import CollectionShare from 'components/CollectionShare';
import { SetDialogMessage } from 'components/MessageDialog';
import React, { useState } from 'react';
import { OverlayTrigger } from 'react-bootstrap';
import { Collection, CollectionType } from 'services/collectionService';
import styled from 'styled-components';
import { getSelectedCollection } from 'utils/collection';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import CollectionOptions from './CollectionOptions';

interface CollectionProps {
    collections: Collection[];
    selected?: number;
    selectCollection: (id?: number) => void;
    setDialogMessage: SetDialogMessage;
    syncWithRemote: () => Promise<void>;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
}

const Container = styled.div`
    margin: 0 auto;
    overflow-y: hidden;
    height: 50px;
    display: flex;
    max-width: 100%;
    @media (min-width: 1000px) {
        width: 1000px;
    }

    @media (min-width: 450px) and (max-width: 1000px) {
        width: 600px;
    }

    @media (max-width: 450px) {
        width: 100%;
    }
`;

const Wrapper = styled.div`
    height: 70px;
    margin-top: 10px;
    flex: 1;
    white-space: nowrap;
    overflow: auto;
    max-width: 100%;
`;
const Option = styled.div`
    display: inline-block;
    opacity: 0;
    font-weight: bold;
    width: 0px;
    margin: 0 9px;
`;
const Chip = styled.button<{ active: boolean }>`
    border-radius: 8px;
    padding: 4px 14px 4px 34px;
    margin: 2px 8px 2px 2px;
    border: none;
    background-color: ${(props) =>
        props.active ? '#fff' : 'rgba(255, 255, 255, 0.3)'};
    outline: none !important;
    &:hover {
        background-color: ${(props) => !props.active && '#bbbbbb'};
    }
    &:hover ${Option} {
        opacity: 1;
        color: #6c6c6c;
    }
`;

export default function Collections(props: CollectionProps) {
    const { selected, collections, selectCollection } = props;
    const [selectedCollectionID, setSelectedCollectionID] = useState<number>(
        null
    );

    const [collectionShareModalView, setCollectionShareModalView] = useState(
        false
    );
    const clickHandler = (collection?: Collection) => () => {
        setSelectedCollectionID(collection?.id);
        selectCollection(collection?.id);
    };

    if (!collections || collections.length === 0) {
        return <Container />;
    }

    return (
        <>
            <CollectionShare
                show={collectionShareModalView}
                onHide={() => setCollectionShareModalView(false)}
                collection={getSelectedCollection(
                    selectedCollectionID,
                    props.collections
                )}
                syncWithRemote={props.syncWithRemote}
            />
            <Container>
                <Wrapper>
                    <Chip active={!selected} onClick={clickHandler()}>
                        All
                        <div
                            style={{ display: 'inline-block', width: '24px' }}
                        />
                    </Chip>
                    {collections?.map((item) => (
                        <Chip
                            key={item.id}
                            active={selected === item.id}
                            onClick={clickHandler(item)}
                        >
                            {item.name}
                            {item.type != CollectionType.favorites && (
                                <OverlayTrigger
                                    rootClose
                                    trigger="click"
                                    placement="bottom"
                                    overlay={CollectionOptions({
                                        syncWithRemote: props.syncWithRemote,
                                        setCollectionNamerAttributes:
                                            props.setCollectionNamerAttributes,
                                        collections: props.collections,
                                        selectedCollectionID,
                                        setDialogMessage:
                                            props.setDialogMessage,
                                        showCollectionShareModal: setCollectionShareModalView.bind(
                                            null,
                                            true
                                        ),
                                    })}
                                >
                                    <Option
                                        onClick={(e) => {
                                            setSelectedCollectionID(item.id);

                                            e.stopPropagation();
                                        }}
                                    >
                                        &#8942;
                                    </Option>
                                </OverlayTrigger>
                            )}
                        </Chip>
                    ))}
                </Wrapper>
            </Container>
        </>
    );
}
