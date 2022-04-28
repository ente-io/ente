import { CollectionSummaries } from 'types/collection';

interface Iprops {
    isOpen: boolean;
    close: () => void;
    collectionSummaries: CollectionSummaries;
    setActiveCollection: (id?: number) => void;
}

import * as React from 'react';
import DialogContent from '@mui/material/DialogContent';
import Typography from '@mui/material/Typography';
import constants from 'utils/strings/constants';
import { FlexWrapper, TwoScreenSpacedOptions } from 'components/Container';
import { LargerCollectionTile } from './styledComponents';
import CollectionCard from './CollectionCard';
import Divider from '@mui/material/Divider';
import { useState } from 'react';
import CollectionSort from 'components/pages/gallery/CollectionSort';
import { COLLECTION_SORT_BY } from 'constants/collection';
import { DialogTitleWithCloseButton } from 'components/MessageDialog';
import { sortCollectionSummaries } from 'services/collectionService';
import { Transition, FloatingSidebar } from 'components/FloatingSidebar';

const LeftSlideTransition = Transition('up');

export default function AllCollections(props: Iprops) {
    const { collectionSummaries, isOpen, close, setActiveCollection } = props;

    const onCollectionClick = (collectionID: number) => {
        setActiveCollection(collectionID);
        close();
    };

    const [collectionSortBy, setCollectionSortBy] =
        useState<COLLECTION_SORT_BY>(COLLECTION_SORT_BY.LATEST_FILE);

    return (
        <>
            <FloatingSidebar
                position="right"
                TransitionComponent={LeftSlideTransition}
                onClose={close}
                open={isOpen}>
                <DialogTitleWithCloseButton onClose={close}>
                    <Typography variant="h6">
                        <strong>{constants.ALL_ALBUMS}</strong>
                    </Typography>
                    <TwoScreenSpacedOptions>
                        <Typography variant="subtitle1">
                            {`${[...props.collectionSummaries.keys()].length} ${
                                constants.ALBUMS
                            }`}
                        </Typography>
                        <CollectionSort
                            activeSortBy={collectionSortBy}
                            setCollectionSortBy={setCollectionSortBy}
                        />
                    </TwoScreenSpacedOptions>
                </DialogTitleWithCloseButton>
                <Divider />
                <DialogContent>
                    <FlexWrapper>
                        {sortCollectionSummaries(
                            [...collectionSummaries.values()],
                            collectionSortBy
                        ).map(
                            ({
                                latestFile,
                                collectionAttributes,
                                fileCount,
                            }) => (
                                <CollectionCard
                                    key={collectionAttributes.id}
                                    latestFile={latestFile}
                                    onClick={() =>
                                        onCollectionClick(
                                            collectionAttributes.id
                                        )
                                    }
                                    customCollectionTile={LargerCollectionTile}>
                                    <div>
                                        <Typography>
                                            <strong>
                                                {collectionAttributes.name}
                                            </strong>
                                        </Typography>
                                        <Typography>
                                            {fileCount} {constants.PHOTOS}
                                        </Typography>
                                    </div>
                                </CollectionCard>
                            )
                        )}
                    </FlexWrapper>
                </DialogContent>
            </FloatingSidebar>
        </>
    );
}
