import React, { useEffect, useState } from 'react';
import AddCollectionButton from './AddCollectionButton';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { User } from 'types/user';
import {
    Collection,
    CollectionSummaries,
    CollectionSummary,
} from 'types/collection';
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
    const [collectionToShow, setCollectionToShow] = useState<
        CollectionSummary[]
    >([]);
    useEffect(() => {
        if (!attributes || !props.open) {
            return;
        }
        const user: User = getData(LS_KEYS.USER);
        const personalCollectionsOtherThanFrom = [
            ...collectionSummaries.values(),
        ]?.filter(
            ({ collectionAttributes }) =>
                collectionAttributes.id !== attributes.fromCollection &&
                collectionAttributes.ownerID === user?.id &&
                collectionAttributes.type !== CollectionType.favorites &&
                collectionAttributes.type !== CollectionType.system
        );
        if (personalCollectionsOtherThanFrom.length === 0) {
            props.onClose();
            attributes.showNextModal();
        } else {
            setCollectionToShow(personalCollectionsOtherThanFrom);
        }
    }, [props.open]);

    if (!attributes) {
        return <></>;
    }

    const handleCollectionClick = (collectionID: number) => {
        const collection = collections.find((c) => c.id === collectionID);
        attributes.callback(collection);
        props.onClose();
    };

    return (
        <DialogBoxBase {...props} maxWidth="md">
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
                            key={collectionSummary.collectionAttributes.id}
                        />
                    ))}
                </FlexWrapper>
            </DialogContent>
        </DialogBoxBase>
    );
}

export default CollectionSelector;
