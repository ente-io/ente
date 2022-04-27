import React, { useContext, useState } from 'react';
import * as CollectionAPI from 'services/collectionService';
import {
    changeCollectionVisibility,
    downloadAllCollectionFiles,
} from 'utils/collection';
import constants from 'utils/strings/constants';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import { Collection } from 'types/collection';
import { IsArchived } from 'utils/magicMetadata';
import { InvertedIconButton } from 'components/Container';
import OptionIcon from 'components/icons/OptionIcon-2';
import Paper from '@mui/material/Paper';
import MenuList from '@mui/material/MenuList';
import { ListItem, Menu, MenuItem } from '@mui/material';
import { GalleryContext } from 'pages/gallery';
import { logError } from 'utils/sentry';
import { VISIBILITY_STATE } from 'types/magicMetadata';

interface CollectionOptionsProps {
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    activeCollection: Collection;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
}

enum CollectionActions {
    RENAME,
    DOWNLOAD,
    ARCHIVE,
    UNARCHIVE,
    DELETE,
}

const CollectionOptions = (props: CollectionOptionsProps) => {
    const {
        activeCollection,
        redirectToAll,
        setCollectionNamerAttributes,
        showCollectionShareModal,
    } = props;
    const { startLoading, finishLoading, setDialogMessage, syncWithRemote } =
        useContext(GalleryContext);

    const [optionEl, setOptionEl] = useState(null);
    const handleClose = () => setOptionEl(null);

    const handleCollectionAction = (action: CollectionActions) => {
        let callback;
        switch (action) {
            case CollectionActions.RENAME:
                callback = renameCollection;
                break;
            case CollectionActions.DOWNLOAD:
                callback = downloadCollection;
                break;
            case CollectionActions.ARCHIVE:
                callback = archiveCollection;
                break;
            case CollectionActions.UNARCHIVE:
                callback = unArchiveCollection;
                break;
            case CollectionActions.DELETE:
                callback = deleteCollection;
                break;
            default:
                logError(
                    Error('invalid collection action '),
                    'handleCollectionAction failed'
                );
                {
                    action;
                }
        }
        return async (...args) => {
            startLoading();
            try {
                await callback(...args);
                handleClose();
            } catch (e) {
                setDialogMessage({
                    title: constants.ERROR,
                    content: constants.UNKNOWN_ERROR,
                    close: { variant: 'danger' },
                });
            }

            syncWithRemote();
            finishLoading();
        };
    };

    const renameCollection = (newName: string) => {
        if (activeCollection.name !== newName) {
            CollectionAPI.renameCollection(activeCollection, newName);
        }
    };

    const deleteCollection = async () => {
        await CollectionAPI.deleteCollection(activeCollection.id);
        redirectToAll();
    };

    const archiveCollection = () => {
        changeCollectionVisibility(activeCollection, VISIBILITY_STATE.ARCHIVED);
    };

    const unArchiveCollection = () => {
        changeCollectionVisibility(activeCollection, VISIBILITY_STATE.VISIBLE);
    };

    const downloadCollection = () => {
        downloadAllCollectionFiles(activeCollection.id);
    };

    const showRenameCollectionModal = () => {
        setCollectionNamerAttributes({
            title: constants.RENAME_COLLECTION,
            buttonText: constants.RENAME,
            autoFilledName: activeCollection.name,
            callback: handleCollectionAction(CollectionActions.RENAME),
        });
    };

    const confirmDeleteCollection = () => {
        setDialogMessage({
            title: constants.CONFIRM_DELETE_COLLECTION,
            content: constants.DELETE_COLLECTION_MESSAGE(),
            staticBackdrop: true,
            proceed: {
                text: constants.DELETE_COLLECTION,
                action: handleCollectionAction(CollectionActions.DELETE),
                variant: 'danger',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    };

    const confirmDownloadCollection = () => {
        setDialogMessage({
            title: constants.CONFIRM_DOWNLOAD_COLLECTION,
            content: constants.DOWNLOAD_COLLECTION_MESSAGE(),
            staticBackdrop: true,
            proceed: {
                text: constants.DOWNLOAD,
                action: handleCollectionAction(CollectionActions.DOWNLOAD),
                variant: 'success',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    };

    return (
        <>
            <InvertedIconButton
                style={{
                    transform: 'rotate(90deg)',
                }}
                onClick={(event) => setOptionEl(event.currentTarget)}
                aria-controls={optionEl ? 'collection-options' : undefined}
                aria-haspopup="true"
                aria-expanded={optionEl ? 'true' : undefined}>
                <OptionIcon />
            </InvertedIconButton>
            <Menu
                id="collection-options"
                anchorEl={optionEl}
                open={Boolean(optionEl)}
                onClose={handleClose}
                MenuListProps={{
                    'aria-labelledby': 'collection-options',
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
                            <ListItem onClick={showCollectionShareModal}>
                                {constants.SHARE}
                            </ListItem>
                        </MenuItem>
                        <MenuItem>
                            <ListItem onClick={confirmDownloadCollection}>
                                {constants.DOWNLOAD}
                            </ListItem>
                        </MenuItem>
                        <MenuItem>
                            {IsArchived(activeCollection) ? (
                                <ListItem
                                    onClick={handleCollectionAction(
                                        CollectionActions.UNARCHIVE
                                    )}>
                                    {constants.UNARCHIVE}
                                </ListItem>
                            ) : (
                                <ListItem
                                    onClick={handleCollectionAction(
                                        CollectionActions.ARCHIVE
                                    )}>
                                    {constants.ARCHIVE}
                                </ListItem>
                            )}
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
