import { CollectionSummaries } from 'types/collection';

interface Iprops {
    isOpen: boolean;
    close: () => void;
    collectionSummaries: CollectionSummaries;
    setActiveCollection: (id?: number) => void;
}

import * as React from 'react';
import PropTypes from 'prop-types';
import Dialog from '@mui/material/Dialog';
import DialogContent from '@mui/material/DialogContent';
import Typography from '@mui/material/Typography';
import Slide from '@mui/material/Slide';
import constants from 'utils/strings/constants';
import { FlexWrapper, TwoScreenSpacedOptions } from 'components/Container';
import { CollectionTile } from '.';
import { styled } from '@mui/material/styles';
import { default as styledComponent } from 'styled-components';
import CollectionCard from './CollectionCard';
import Divider from '@mui/material/Divider';
import { useState } from 'react';
import CollectionSort from 'components/pages/gallery/CollectionSort';
import { COLLECTION_SORT_BY } from 'constants/collection';
import { DialogTitleWithCloseButton } from 'components/MessageDialog';

const StyledDialog = styled(Dialog)(({ theme }) => ({
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2),
    },
    '& .MuiDialogActions-root': {
        padding: theme.spacing(1),
    },
    '& .MuiPaper-root': {
        maxWidth: '510px',
    },
    '& .MuiDialog-container': {
        justifyContent: 'flex-end',
    },
}));

StyledDialog.propTypes = {
    children: PropTypes.node,
    onClose: PropTypes.func.isRequired,
};

const Transition = React.forwardRef(
    (props: { children: React.ReactElement<any, any> }, ref) => {
        return <Slide direction="left" ref={ref} {...props} />;
    }
);

const LargerCollectionTile = styledComponent(CollectionTile)`
    width: 150px;
    height: 150px;
    align-items:flex-start;
    margin:4px;
`;

export default function AllCollections(props: Iprops) {
    const { collectionSummaries, isOpen, close, setActiveCollection } = props;

    const onCollectionClick = (collectionID: number) => {
        setActiveCollection(collectionID);
        close();
    };

    const [collectionSortBy, setCollectionSortBy] =
        useState<COLLECTION_SORT_BY>(COLLECTION_SORT_BY.LATEST_FILE);

    return (
        <div>
            <StyledDialog
                TransitionComponent={Transition}
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
                        {[...collectionSummaries.entries()].map(
                            ([id, collectionSummary]) => (
                                <CollectionCard
                                    key={id}
                                    latestFile={collectionSummary.latestFile}
                                    onClick={() => onCollectionClick(id)}
                                    customCollectionTile={LargerCollectionTile}>
                                    <div>
                                        <Typography>
                                            <strong>
                                                {
                                                    collectionSummary.collectionName
                                                }
                                            </strong>
                                        </Typography>
                                        <Typography>
                                            {collectionSummary.fileCount}{' '}
                                            {constants.PHOTOS}
                                        </Typography>
                                    </div>
                                </CollectionCard>
                            )
                        )}
                    </FlexWrapper>
                </DialogContent>
            </StyledDialog>
        </div>
    );
}
