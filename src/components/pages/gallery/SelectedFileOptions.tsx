import React, { useContext, useEffect, useState } from 'react';
import { SetCollectionSelectorAttributes } from './CollectionSelector';
import DeleteIcon from 'components/icons/DeleteIcon';
import CloseIcon from '@mui/icons-material/Close';
import AddIcon from 'components/icons/AddIcon';
import { FluidContainer, IconButton } from 'components/Container';
import constants from 'utils/strings/constants';
import Archive from 'components/icons/Archive';
import MoveIcon from 'components/icons/MoveIcon';
import { COLLECTION_OPS_TYPE } from 'utils/collection';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    TRASH_SECTION,
} from 'constants/collection';
import UnArchive from 'components/icons/UnArchive';
import { Collection } from 'types/collection';
import RemoveIcon from 'components/icons/RemoveIcon';
import RestoreIcon from 'components/icons/RestoreIcon';
import ClockIcon from 'components/icons/ClockIcon';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { FIX_CREATION_TIME_VISIBLE_TO_USER_IDS } from 'constants/user';
import DownloadIcon from 'components/icons/DownloadIcon';
import { User } from 'types/user';
import { IconWithMessage } from 'components/IconWithMessage';
import { SelectionBar } from '../../Navbar/SelectionBar';
import { AppContext } from 'pages/_app';

interface Props {
    addToCollectionHelper: (collection: Collection) => void;
    moveToCollectionHelper: (collection: Collection) => void;
    restoreToCollectionHelper: (collection: Collection) => void;
    showCreateCollectionModal: (opsType: COLLECTION_OPS_TYPE) => () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    deleteFileHelper: (permanent?: boolean) => void;
    removeFromCollectionHelper: () => void;
    fixTimeHelper: () => void;
    downloadHelper: () => void;
    count: number;
    clearSelection: () => void;
    archiveFilesHelper: () => void;
    unArchiveFilesHelper: () => void;
    activeCollection: number;
    isFavoriteCollection: boolean;
}

const SelectedFileOptions = ({
    addToCollectionHelper,
    moveToCollectionHelper,
    restoreToCollectionHelper,
    showCreateCollectionModal,
    removeFromCollectionHelper,
    fixTimeHelper,
    setCollectionSelectorAttributes,
    deleteFileHelper,
    downloadHelper,
    count,
    clearSelection,
    archiveFilesHelper,
    unArchiveFilesHelper,
    activeCollection,
    isFavoriteCollection,
}: Props) => {
    const { setDialogMessage } = useContext(AppContext);
    const [showFixCreationTime, setShowFixCreationTime] = useState(false);
    useEffect(() => {
        const user: User = getData(LS_KEYS.USER);
        const showFixCreationTime =
            FIX_CREATION_TIME_VISIBLE_TO_USER_IDS.includes(user?.id);
        setShowFixCreationTime(showFixCreationTime);
    }, []);
    const addToCollection = () =>
        setCollectionSelectorAttributes({
            callback: addToCollectionHelper,
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.ADD),
            title: constants.ADD_TO_COLLECTION,
            fromCollection: activeCollection,
        });

    const trashHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_DELETE,
            content: constants.TRASH_MESSAGE,
            proceed: {
                action: deleteFileHelper,
                text: constants.MOVE_TO_TRASH,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });

    const permanentlyDeleteHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_DELETE,
            content: constants.DELETE_MESSAGE,
            proceed: {
                action: () => deleteFileHelper(true),
                text: constants.DELETE,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });

    const restoreHandler = () =>
        setCollectionSelectorAttributes({
            callback: restoreToCollectionHelper,
            showNextModal: showCreateCollectionModal(
                COLLECTION_OPS_TYPE.RESTORE
            ),
            title: constants.RESTORE_TO_COLLECTION,
        });

    const removeFromCollectionHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_REMOVE,
            content: constants.CONFIRM_REMOVE_MESSAGE(),

            proceed: {
                action: removeFromCollectionHelper,
                text: constants.REMOVE,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });

    const moveToCollection = () => {
        setCollectionSelectorAttributes({
            callback: moveToCollectionHelper,
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.MOVE),
            title: constants.MOVE_TO_COLLECTION,
            fromCollection: activeCollection,
        });
    };

    return (
        <SelectionBar>
            <FluidContainer>
                <IconButton onClick={clearSelection}>
                    <CloseIcon />
                </IconButton>
                <div>
                    {count} {constants.SELECTED}
                </div>
            </FluidContainer>
            {activeCollection === TRASH_SECTION ? (
                <>
                    <IconWithMessage message={constants.RESTORE}>
                        <IconButton onClick={restoreHandler}>
                            <RestoreIcon />
                        </IconButton>
                    </IconWithMessage>
                    <IconWithMessage message={constants.DELETE_PERMANENTLY}>
                        <IconButton onClick={permanentlyDeleteHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </IconWithMessage>
                </>
            ) : (
                <>
                    {showFixCreationTime && (
                        <IconWithMessage message={constants.FIX_CREATION_TIME}>
                            <IconButton onClick={fixTimeHelper}>
                                <ClockIcon />
                            </IconButton>
                        </IconWithMessage>
                    )}
                    <IconWithMessage message={constants.DOWNLOAD}>
                        <IconButton onClick={downloadHelper}>
                            <DownloadIcon />
                        </IconButton>
                    </IconWithMessage>
                    <IconWithMessage message={constants.ADD}>
                        <IconButton onClick={addToCollection}>
                            <AddIcon />
                        </IconButton>
                    </IconWithMessage>
                    {activeCollection === ARCHIVE_SECTION && (
                        <IconWithMessage message={constants.UNARCHIVE}>
                            <IconButton onClick={unArchiveFilesHelper}>
                                <UnArchive />
                            </IconButton>
                        </IconWithMessage>
                    )}
                    {activeCollection === ALL_SECTION && (
                        <IconWithMessage message={constants.ARCHIVE}>
                            <IconButton onClick={archiveFilesHelper}>
                                <Archive />
                            </IconButton>
                        </IconWithMessage>
                    )}

                    {activeCollection !== ALL_SECTION &&
                        activeCollection !== ARCHIVE_SECTION &&
                        !isFavoriteCollection && (
                            <>
                                <IconWithMessage message={constants.MOVE}>
                                    <IconButton onClick={moveToCollection}>
                                        <MoveIcon />
                                    </IconButton>
                                </IconWithMessage>

                                <IconWithMessage message={constants.REMOVE}>
                                    <IconButton
                                        onClick={removeFromCollectionHandler}>
                                        <RemoveIcon />
                                    </IconButton>
                                </IconWithMessage>
                            </>
                        )}
                    <IconWithMessage message={constants.DELETE}>
                        <IconButton onClick={trashHandler}>
                            <DeleteIcon />
                        </IconButton>
                    </IconWithMessage>
                </>
            )}
        </SelectionBar>
    );
};

export default SelectedFileOptions;
