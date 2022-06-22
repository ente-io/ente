import React, { useContext } from 'react';
import * as CollectionAPI from 'services/collectionService';
import {
    changeCollectionVisibility,
    downloadAllCollectionFiles,
} from 'utils/collection';
import constants from 'utils/strings/constants';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import { Collection } from 'types/collection';
import { IsArchived } from 'utils/magicMetadata';
import { GalleryContext } from 'pages/gallery';
import { logError } from 'utils/sentry';
import { VISIBILITY_STATE } from 'types/magicMetadata';
import { AppContext } from 'pages/_app';
import OverflowMenu from 'components/OverflowMenu/menu';
import { OverflowMenuOption } from 'components/OverflowMenu/option';
import MoreVertIcon from '@mui/icons-material/MoreVert';

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
    const { startLoading, finishLoading, setDialogMessage } =
        useContext(AppContext);
    const { syncWithRemote } = useContext(GalleryContext);

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
            proceed: {
                text: constants.DOWNLOAD,
                action: handleCollectionAction(CollectionActions.DOWNLOAD),
                variant: 'accent',
            },
            close: {
                text: constants.CANCEL,
            },
        });
    };

    return (
        <OverflowMenu
            ariaControls={`collection-options-${props.activeCollection.id}`}
            triggerButtonIcon={<MoreVertIcon />}
            triggerButtonProps={{
                sx: {
                    background: (theme) => theme.palette.background.paper,
                },
            }}>
            <OverflowMenuOption onClick={showRenameCollectionModal}>
                {constants.RENAME}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={showCollectionShareModal}>
                {constants.SHARE}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={confirmDownloadCollection}>
                {constants.DOWNLOAD}
            </OverflowMenuOption>
            {IsArchived(activeCollection) ? (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.UNARCHIVE
                    )}>
                    {constants.UNARCHIVE}
                </OverflowMenuOption>
            ) : (
                <OverflowMenuOption
                    onClick={handleCollectionAction(CollectionActions.ARCHIVE)}>
                    {constants.ARCHIVE}
                </OverflowMenuOption>
            )}
            <OverflowMenuOption
                color="danger"
                onClick={confirmDeleteCollection}>
                {constants.DELETE}
            </OverflowMenuOption>
        </OverflowMenu>
    );
};

export default CollectionOptions;
