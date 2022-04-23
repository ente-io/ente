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
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import CloseIcon from '@mui/icons-material/Close';
import Typography from '@mui/material/Typography';
import Slide from '@mui/material/Slide';
import constants from 'utils/strings/constants';
import { FlexWrapper, TwoScreenSpacedOptions } from 'components/Container';
import SortIcon from 'components/icons/SortIcon';
import IconButton from '@mui/material/IconButton';
import { CollectionTile } from '.';
import { styled } from '@mui/material/styles';
import { default as styledComponent } from 'styled-components';
import CollectionCard from './CollectionCard';
import Divider from '@mui/material/Divider';

const BootstrapDialog = styled(Dialog)(({ theme }) => ({
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2),
    },
    '& .MuiDialogActions-root': {
        padding: theme.spacing(1),
    },
    '& .MuiPaper-root': {
        backgroundImage: 'none',
        maxWidth: '510px',
    },
    left: '40%',
}));

const BootstrapDialogTitle = (props) => {
    const { children, onClose, ...other } = props;

    return (
        <DialogTitle sx={{ m: 0, p: 2 }} {...other}>
            {children}
            {onClose ? (
                <IconButton
                    aria-label="close"
                    onClick={onClose}
                    sx={{
                        position: 'absolute',
                        right: 8,
                        top: 8,
                        color: (theme) => theme.palette.grey[500],
                    }}>
                    <CloseIcon />
                </IconButton>
            ) : null}
        </DialogTitle>
    );
};

BootstrapDialogTitle.propTypes = {
    children: PropTypes.node,
    onClose: PropTypes.func.isRequired,
};

const Transition = React.forwardRef((props, ref) => {
    return <Slide direction="left" ref={ref} {...props} />;
});

const LargerCollectionTile = styledComponent(CollectionTile)`
    width: 150px;
    height: 150px;
    align-items:flex-start;
    margin:4px;
`;

export default function AllCollections(props: Iprops) {
    const { collectionSummaries, isOpen, close, setActiveCollection } = props;

    const onCollectionClick = (collectionID: number) => {
        console.log(collectionID);
        setActiveCollection(collectionID);
        close();
    };
    return (
        <div>
            <BootstrapDialog
                TransitionComponent={Transition}
                onClose={close}
                open={isOpen}>
                <BootstrapDialogTitle onClose={close}>
                    <Typography variant="h6">
                        <strong>{constants.ALL_ALBUMS}</strong>
                    </Typography>
                    <TwoScreenSpacedOptions>
                        <Typography variant="subtitle">
                            {`${[...props.collectionSummaries.keys()].length} ${
                                constants.ALBUMS
                            }`}
                        </Typography>
                        <IconButton>
                            <SortIcon />
                        </IconButton>
                    </TwoScreenSpacedOptions>
                </BootstrapDialogTitle>
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
            </BootstrapDialog>
        </div>
    );
}
