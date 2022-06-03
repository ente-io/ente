import React, { useEffect, useMemo } from 'react';
import AddCollectionButton from './AddCollectionButton';
import { Collection, CollectionSummaries } from 'types/collection';
import { CollectionType } from 'constants/collection';
import DialogBoxBase from 'components/DialogBox/base';
import DialogTitleWithCloseButton from 'components/DialogBox/titleWithCloseButton';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import { CollectionSelectorTile } from 'components/Collections/styledComponents';
import AllCollectionCard from 'components/Collections/AllCollections/CollectionCard';

export interface CollectionSelectorAttributes {
    callback: (collection: Collection) => void;
    showNextModal: () => void;
    title: string;
    fromCollection?: number;
}
export type SetCollectionSelectorAttributes = React.Dispatch<
    React.SetStateAction<CollectionSelectorAttributes>
>;

interface Props {
    open: boolean;
    onClose: (closeBtnClick?: boolean) => void;
    attributes: CollectionSelectorAttributes;
    collections: Collection[];
    collectionSummaries: CollectionSummaries;
}
function CollectionSelector({
    attributes,
    collectionSummaries,
    collections,
    ...props
}: Props) {
    const collectionToShow = useMemo(() => {
        const personalCollectionsOtherThanFrom = [
            ...collectionSummaries.values(),
        ]?.filter(
            ({ type, id, isSharedAlbum }) =>
                id !== attributes.fromCollection &&
                !isSharedAlbum &&
                type !== CollectionType.favorites &&
                type !== CollectionType.system
        );
        return personalCollectionsOtherThanFrom;
    }, [collectionSummaries]);

    useEffect(() => {
        if (!attributes || !props.open) {
            return;
        }
        if (collectionToShow.length === 0) {
            props.onClose();
            attributes.showNextModal();
        }
    }, [collectionToShow, attributes, props.open]);

    if (!attributes) {
        return <></>;
    }

    const handleCollectionClick = (collectionID: number) => {
        const collection = collections.find((c) => c.id === collectionID);
        attributes.callback(collection);
        props.onClose();
    };

    return (
        <DialogBoxBase
            {...props}
            maxWidth="md"
            PaperProps={{ sx: { maxWidth: '848px' } }}>
            <DialogTitleWithCloseButton onClose={() => props.onClose(true)}>
                {attributes.title}
            </DialogTitleWithCloseButton>
            <DialogContent
                sx={{
                    '&&&': {
                        px: 0,
                    },
                }}>
                <FlexWrapper style={{ flexWrap: 'wrap' }}>
                    <AddCollectionButton
                        showNextModal={attributes.showNextModal}
                    />
                    {collectionToShow.map((collectionSummary) => (
                        <AllCollectionCard
                            collectionTile={CollectionSelectorTile}
                            onCollectionClick={handleCollectionClick}
                            collectionSummary={collectionSummary}
                            key={collectionSummary.id}
                        />
                    ))}
                </FlexWrapper>
            </DialogContent>
        </DialogBoxBase>
    );
}

export default CollectionSelector;
