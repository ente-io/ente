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
import CollectionSort from 'components/pages/gallery/CollectionSort';
import { COLLECTION_SORT_BY } from 'constants/collection';
import { sortCollectionSummaries } from 'services/collectionService';
import { Transition, FloatingSidebar } from 'components/FloatingSidebar';
import { useLocalState } from 'hooks/useLocalState';
import { LS_KEYS } from 'utils/storage/localStorage';
import DialogTitleWithCloseButton from 'components/MessageDialog/TitleWithCloseButton';
import { DialogTitle } from '@mui/material';

const LeftSlideTransition = Transition('up');

export default function AllCollections(props: Iprops) {
    const { collectionSummaries, isOpen, close, setActiveCollection } = props;

    const onCollectionClick = (collectionID: number) => {
        setActiveCollection(collectionID);
        close();
    };

    const [collectionSortBy, setCollectionSortBy] =
        useLocalState<COLLECTION_SORT_BY>(
            LS_KEYS.COLLECTION_SORT_BY,
            COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING
        );

    return (
        <>
            <FloatingSidebar
                position="right"
                TransitionComponent={LeftSlideTransition}
                onClose={close}
                open={isOpen}>
                <DialogTitleWithCloseButton onClose={close} sx={{ pb: 0 }}>
                    <Typography variant="h6">
                        <strong>{constants.ALL_ALBUMS}</strong>
                    </Typography>
                </DialogTitleWithCloseButton>
                <DialogTitle sx={{ pt: 0 }}>
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
                </DialogTitle>
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
