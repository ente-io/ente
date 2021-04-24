import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import React, { useState } from 'react';
import { Dropdown } from 'react-bootstrap';
import {
    Collection,
    CollectionType,
    deleteCollection,
    renameCollection,
} from 'services/collectionService';
import styled from 'styled-components';
import { SetConfirmAction } from 'utils/billingUtil';
import constants from 'utils/strings/constants';
import NameCollection from './NameCollection';

interface CollectionProps {
    collections: Collection[];
    selected?: number;
    selectCollection: (id?: number) => void;
    setConfirmAction: SetConfirmAction;
    syncWithRemote: Function;
}

const Container = styled.div`
    margin: 0 auto;
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
    margin-top: 10px;
    white-space: nowrap;
    max-width: 100%;
`;
const Option = styled.div`
    display: inline-block;
    opacity: 0;
    font-weight: bold;
    padding-left: 5px;
`;
const Chip = styled.button<{ active: boolean }>`
    border-radius: 8px;
    padding: 4px 14px;
    margin: 2px 8px 2px 2px;
    border: none;
    background-color: ${(props) =>
        props.active ? '#fff' : 'rgba(255, 255, 255, 0.3)'};
    outline: none !important;

    &:focus {
        box-shadow: 0 0 0 2px #2666cc;
        background-color: #eee;
    }
    &:hover ${Option} {
        opacity: 1;
        color: ${(props) => (props.active ? 'black' : 'white')};
    }
`;

export default function Collections(props: CollectionProps) {
    const { selected, collections, selectCollection } = props;
    const [selectedCollection, setSelectedCollection] = useState(null);
    const [renameCollectionModalView, setRenameCollectionModalView] = useState(
        false
    );
    const clickHandler = (collection?: Collection) => () => {
        setSelectedCollection(collection);
        selectCollection(collection.id);
    };

    if (!collections || collections.length === 0) {
        return <Container />;
    }
    const CustomToggle = React.forwardRef<any, { onClick }>(
        ({ children, onClick }, ref) => (
            <Option
                ref={ref}
                onClick={(e) => {
                    e.preventDefault();
                    onClick(e);
                }}
            >
                {children}
                &#8942;
            </Option>
        )
    );
    const collectionRename = async (selectedCollection, albumName) => {
        await renameCollection(selectedCollection, albumName);
        props.syncWithRemote();
    };
    return (
        <>
            <NameCollection
                show={renameCollectionModalView}
                onHide={() => setRenameCollectionModalView(false)}
                autoFilledName={selectedCollection?.name}
                callback={collectionRename.bind(null, selectedCollection)}
                purpose={{
                    title: constants.RENAME_COLLECTION,
                    buttonText: constants.RENAME,
                }}
            />
            <Container>
                <Wrapper>
                    <Chip active={!selected} onClick={clickHandler()}>
                        All
                    </Chip>
                    {collections?.map((item, index) => (
                        <Chip
                            key={item.id}
                            active={selected === item.id}
                            onClick={clickHandler(item)}
                        >
                            <Dropdown>
                                {item.name}
                                {item.type != CollectionType.favorites && (
                                    <>
                                        <Dropdown.Toggle
                                            as={CustomToggle}
                                            split
                                        />
                                        <Dropdown.Menu>
                                            <Dropdown.Item
                                                onClick={() => {
                                                    setRenameCollectionModalView(
                                                        true
                                                    );
                                                }}
                                            >
                                                {constants.RENAME}
                                            </Dropdown.Item>
                                            <Dropdown.Item
                                                onClick={() => {
                                                    props.setConfirmAction({
                                                        action:
                                                            CONFIRM_ACTION.DELETE_COLLECTION,
                                                        callback: deleteCollection.bind(
                                                            null,
                                                            item.id,
                                                            props.syncWithRemote
                                                        ),
                                                    });
                                                }}
                                            >
                                                {constants.DELETE}
                                            </Dropdown.Item>
                                        </Dropdown.Menu>
                                    </>
                                )}
                            </Dropdown>
                        </Chip>
                    ))}
                </Wrapper>
            </Container>
        </>
    );
}
