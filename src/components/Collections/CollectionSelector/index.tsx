import React, { useContext, useEffect, useMemo } from 'react';
import { Collection, CollectionSummaries } from 'types/collection';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { isUploadAllowedCollection } from 'utils/collection';
import { AppContext } from 'pages/_app';
import { AllCollectionDialog } from 'components/Collections/AllCollections/dialog';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import CollectionSelectorCard from './CollectionCard';
import AddCollectionButton from './AddCollectionButton';

export interface CollectionSelectorAttributes {
    callback: (collection: Collection) => void;
    showNextModal: () => void;
    title: string;
    fromCollection?: number;
    onCancel?: () => void;
}

interface Props {
    open: boolean;
    onClose: () => void;
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
    const appContext = useContext(AppContext);
    const collectionToShow = useMemo(() => {
        const personalCollectionsOtherThanFrom = [
            ...collectionSummaries.values(),
        ]?.filter(
            ({ type, id }) =>
                id !== attributes?.fromCollection &&
                isUploadAllowedCollection(type)
        );
        return personalCollectionsOtherThanFrom;
    }, [collectionSummaries, attributes]);

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

    const onUserTriggeredClose = () => {
        attributes.onCancel?.();
        props.onClose();
    };

    return (
        <AllCollectionDialog
            onClose={onUserTriggeredClose}
            open={props.open}
            position="center"
            fullScreen={appContext.isMobile}>
            <DialogTitleWithCloseButton onClose={onUserTriggeredClose}>
                {attributes.title}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <FlexWrapper flexWrap="wrap" gap={0.5}>
                    <AddCollectionButton
                        showNextModal={attributes.showNextModal}
                    />
                    {collectionToShow.map((collectionSummary) => (
                        <CollectionSelectorCard
                            onCollectionClick={handleCollectionClick}
                            collectionSummary={collectionSummary}
                            key={collectionSummary.id}
                        />
                    ))}
                </FlexWrapper>
            </DialogContent>
        </AllCollectionDialog>
    );
}

export default CollectionSelector;
