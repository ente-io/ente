import React, { useState } from 'react';
import { SetDialogMessage } from 'components/MessageDialog';
import { deleteCollection, renameCollection } from 'services/collectionService';
import {
    changeCollectionVisibilityHelper,
    downloadCollection,
    getSelectedCollection,
} from 'utils/collection';
import constants from 'utils/strings/constants';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import { sleep } from 'utils/common';
import { Collection } from 'types/collection';
import { IsArchived } from 'utils/magicMetadata';
import { InvertedIconButton } from 'components/Container';
import OptionIcon from 'components/icons/OptionIcon-2';
import Paper from '@mui/material/Paper';
import MenuList from '@mui/material/MenuList';
import { ListItem, Menu, MenuItem } from '@mui/material';

interface CollectionOptionsProps {
    syncWithRemote: () => Promise<void>;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    collections: Collection[];
    activeCollection: number;
    setDialogMessage: SetDialogMessage;
    startLoading: () => void;
    finishLoading: () => void;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
}

const CollectionOptions = (props: CollectionOptionsProps) => {
    const [optionEl, setOptionEl] = useState(null);
    const handleClose = () => setOptionEl(null);

    const collectionRename = async (
        selectedCollection: Collection,
        newName: string
    ) => {
        if (selectedCollection.name !== newName) {
            await renameCollection(selectedCollection, newName);
            props.syncWithRemote();
        }
    };
    const showRenameCollectionModal = () => {
        props.setCollectionNamerAttributes({
            title: constants.RENAME_COLLECTION,
            buttonText: constants.RENAME,
            autoFilledName: getSelectedCollection(
                props.activeCollection,
                props.collections
            )?.name,
            callback: (newName) => {
                props.startLoading();
                collectionRename(
                    getSelectedCollection(
                        props.activeCollection,
                        props.collections
                    ),
                    newName
                );
            },
        });
    };
    const confirmDeleteCollection = () => {
        props.setDialogMessage({
            title: constants.CONFIRM_DELETE_COLLECTION,
            content: constants.DELETE_COLLECTION_MESSAGE(),
            staticBackdrop: true,
            proceed: {
                text: constants.DELETE_COLLECTION,
                action: () => {
                    props.startLoading();
                    deleteCollection(
                        props.activeCollection,
                        props.syncWithRemote,
                        props.redirectToAll,
                        props.setDialogMessage
                    );
                },
                variant: 'danger',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    };

    const archiveCollectionHelper = () => {
        changeCollectionVisibilityHelper(
            getSelectedCollection(props.activeCollection, props.collections),
            props.startLoading,
            props.finishLoading,
            props.setDialogMessage,
            props.syncWithRemote
        );
    };

    const confirmDownloadCollection = () => {
        props.setDialogMessage({
            title: constants.CONFIRM_DOWNLOAD_COLLECTION,
            content: constants.DOWNLOAD_COLLECTION_MESSAGE(),
            staticBackdrop: true,
            proceed: {
                text: constants.DOWNLOAD,
                action: downloadCollectionHelper,
                variant: 'success',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    };

    const downloadCollectionHelper = async () => {
        props.startLoading();
        await downloadCollection(
            props.activeCollection,
            props.setDialogMessage
        );
        await sleep(1000);
        props.finishLoading();
    };

    return (
        <>
            <InvertedIconButton
                style={{
                    transform: 'rotate(90deg)',
                }}
                onClick={(event) => setOptionEl(event.currentTarget)}
                aria-controls={optionEl ? 'basic-menu' : undefined}
                aria-haspopup="true"
                aria-expanded={optionEl ? 'true' : undefined}>
                <OptionIcon />
            </InvertedIconButton>
            <Menu
                id="basic-menu"
                anchorEl={optionEl}
                open={Boolean(optionEl)}
                onClose={handleClose}
                MenuListProps={{
                    'aria-labelledby': 'basic-button',
                }}>
                <Paper sx={{ borderRadius: '10px' }}>
                    <MenuList
                        sx={{
                            padding: 0,
                            border: 'none',
                            borderRadius: '8px',
                        }}>
                        <MenuItem>
                            <ListItem onClick={showRenameCollectionModal}>
                                {constants.RENAME}
                            </ListItem>
                        </MenuItem>
                        <MenuItem>
                            <ListItem onClick={props.showCollectionShareModal}>
                                {constants.SHARE}
                            </ListItem>
                        </MenuItem>
                        <MenuItem>
                            <ListItem onClick={confirmDownloadCollection}>
                                {constants.DOWNLOAD}
                            </ListItem>
                        </MenuItem>
                        <MenuItem>
                            <ListItem onClick={archiveCollectionHelper}>
                                {IsArchived(
                                    getSelectedCollection(
                                        props.activeCollection,
                                        props.collections
                                    )
                                )
                                    ? constants.UNARCHIVE
                                    : constants.ARCHIVE}
                            </ListItem>
                        </MenuItem>
                        <MenuItem>
                            <ListItem
                                color="danger"
                                onClick={confirmDeleteCollection}>
                                {constants.DELETE}
                            </ListItem>
                        </MenuItem>
                    </MenuList>
                </Paper>
            </Menu>
        </>
    );
};

export default CollectionOptions;
