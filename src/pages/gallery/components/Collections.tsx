import CollectionShare from 'components/CollectionShare';
import { SetDialogMessage } from 'components/MessageDialog';
import NavigationButton, {
    SCROLL_DIRECTION,
} from 'components/navigationButton';
import React, { useRef, useState } from 'react';
import { OverlayTrigger } from 'react-bootstrap';
import { Collection, CollectionType } from 'services/collectionService';
import { User } from 'services/userService';
import styled from 'styled-components';
import { getSelectedCollection } from 'utils/collection';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import CollectionOptions from './CollectionOptions';
import OptionIcon, { OptionIconWrapper } from './OptionIcon';

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

const Chip = styled.button<{ active: boolean }>`
    border-radius: 8px;
    padding: 4px;
    padding-left: 24px;
    margin: 2px;
    border: none;
    background-color: ${(props) =>
        props.active ? '#fff' : 'rgba(255, 255, 255, 0.3)'};
    outline: none !important;
    &:hover {
        background-color: ${(props) => !props.active && '#bbbbbb'};
    }
    &:hover ${OptionIconWrapper} {
        opacity: 1;
        color: #000000;
    }
`;

export default function Collections(props: CollectionProps) {
    const { selected, collections, selectCollection } = props;
    const [selectedCollectionID, setSelectedCollectionID] = useState<number>(
        null
    );
    const collectionRef = useRef<HTMLDivElement>(null);
    const [collectionShareModalView, setCollectionShareModalView] = useState(
        false
    );
    const clickHandler = (collection?: Collection) => () => {
        setSelectedCollectionID(collection?.id);
        selectCollection(collection?.id);
    };
    const user: User = getData(LS_KEYS.USER);

    if (!collections || collections.length === 0) {
        return <Container />;
    }
    const collectionOptions = CollectionOptions({
        syncWithRemote: props.syncWithRemote,
        setCollectionNamerAttributes: props.setCollectionNamerAttributes,
        collections: props.collections,
        selectedCollectionID,
        setDialogMessage: props.setDialogMessage,
        showCollectionShareModal: setCollectionShareModalView.bind(null, true),
        redirectToAll: selectCollection.bind(null, null),
    });
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
                <NavigationButton
                    collectionRef={collectionRef}
                    scrollDirection={SCROLL_DIRECTION.LEFT}
                />
                <Wrapper ref={collectionRef}>
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
                            {item.type != CollectionType.favorites &&
                            item.owner.id === user?.id ? (
                                <OverlayTrigger
                                    rootClose
                                    trigger="click"
                                    placement="bottom"
                                    overlay={collectionOptions}
                                >
                                    <OptionIcon
                                        onClick={() =>
                                            setSelectedCollectionID(item.id)
                                        }
                                    />
                                </OverlayTrigger>
                            ) : (
                                <div
                                    style={{
                                        display: 'inline-block',
                                        width: '24px',
                                    }}
                                />
                            )}
                        </Chip>
                    ))}
                </Wrapper>
                <NavigationButton
                    collectionRef={collectionRef}
                    scrollDirection={SCROLL_DIRECTION.RIGHT}
                />
            </Container>
        </>
    );
}
