import React, { useContext } from 'react';
import { SetCollectionSelectorAttributes } from 'types/gallery';
import { FluidContainer } from 'components/Container';
import constants from 'utils/strings/constants';
import { COLLECTION_OPS_TYPE } from 'utils/collection';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    TRASH_SECTION,
} from 'constants/collection';
import { Collection } from 'types/collection';
import { SelectionBar } from '../../Navbar/SelectionBar';
import { AppContext } from 'pages/_app';
import { Box, IconButton, Stack, Tooltip } from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import RestoreIcon from '@mui/icons-material/Restore';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import ClockIcon from '@mui/icons-material/AccessTime';
import DownloadIcon from '@mui/icons-material/Download';
import UnArchiveIcon from '@mui/icons-material/Unarchive';
import ArchiveIcon from '@mui/icons-material/ArchiveOutlined';
import MoveIcon from '@mui/icons-material/ArrowForward';
import RemoveIcon from '@mui/icons-material/RemoveCircleOutline';
import { getTrashFilesMessage } from 'utils/ui';

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
    ownCount: number;
    clearSelection: () => void;
    archiveFilesHelper: () => void;
    unArchiveFilesHelper: () => void;
    activeCollection: number;
    isFavoriteCollection: boolean;
    isUncategorizedCollection: boolean;
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
    ownCount,
    clearSelection,
    archiveFilesHelper,
    unArchiveFilesHelper,
    activeCollection,
    isFavoriteCollection,
    isUncategorizedCollection,
}: Props) => {
    const { setDialogMessage } = useContext(AppContext);
    const addToCollection = () =>
        setCollectionSelectorAttributes({
            callback: addToCollectionHelper,
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.ADD),
            title: constants.ADD_TO_COLLECTION,
            fromCollection: activeCollection,
        });

    const trashHandler = () =>
        setDialogMessage(getTrashFilesMessage(deleteFileHelper));

    const permanentlyDeleteHandler = () =>
        setDialogMessage({
            title: constants.DELETE_FILES_TITLE,
            content: constants.DELETE_FILES_MESSAGE,
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

    const removeFromCollectionHandler = () => {
        if (ownCount === count) {
            setDialogMessage({
                title: constants.REMOVE_FROM_COLLECTION,
                content: constants.CONFIRM_SELF_REMOVE_MESSAGE(),

                proceed: {
                    action: removeFromCollectionHelper,
                    text: constants.YES_REMOVE,
                    variant: 'primary',
                },
                close: { text: constants.CANCEL },
            });
        } else {
            setDialogMessage({
                title: constants.REMOVE_FROM_COLLECTION,
                content: constants.CONFIRM_SELF_AND_OTHER_REMOVE_MESSAGE(),

                proceed: {
                    action: removeFromCollectionHelper,
                    text: constants.YES_REMOVE,
                    variant: 'danger',
                },
                close: { text: constants.CANCEL },
            });
        }
    };

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
                <Box ml={1.5}>
                    {count} {constants.SELECTED}{' '}
                    {ownCount !== count && `(${ownCount} ${constants.YOURS})`}
                </Box>
            </FluidContainer>
            <Stack spacing={2} direction="row" mr={2}>
                {activeCollection === TRASH_SECTION ? (
                    <>
                        <Tooltip title={constants.RESTORE}>
                            <IconButton onClick={restoreHandler}>
                                <RestoreIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={constants.DELETE_PERMANENTLY}>
                            <IconButton onClick={permanentlyDeleteHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : isUncategorizedCollection ? (
                    <>
                        <Tooltip title={constants.MOVE}>
                            <IconButton onClick={moveToCollection}>
                                <MoveIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={constants.DELETE}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : (
                    <>
                        <Tooltip title={constants.FIX_CREATION_TIME}>
                            <IconButton onClick={fixTimeHelper}>
                                <ClockIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={constants.DOWNLOAD}>
                            <IconButton onClick={downloadHelper}>
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={constants.ADD}>
                            <IconButton onClick={addToCollection}>
                                <AddIcon />
                            </IconButton>
                        </Tooltip>
                        {activeCollection === ARCHIVE_SECTION && (
                            <Tooltip title={constants.UNARCHIVE}>
                                <IconButton onClick={unArchiveFilesHelper}>
                                    <UnArchiveIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                        {activeCollection === ALL_SECTION && (
                            <Tooltip title={constants.ARCHIVE}>
                                <IconButton onClick={archiveFilesHelper}>
                                    <ArchiveIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                        {activeCollection !== ALL_SECTION &&
                            activeCollection !== ARCHIVE_SECTION &&
                            !isFavoriteCollection && (
                                <>
                                    <Tooltip title={constants.MOVE}>
                                        <IconButton onClick={moveToCollection}>
                                            <MoveIcon />
                                        </IconButton>
                                    </Tooltip>

                                    <Tooltip title={constants.REMOVE}>
                                        <IconButton
                                            onClick={
                                                removeFromCollectionHandler
                                            }>
                                            <RemoveIcon />
                                        </IconButton>
                                    </Tooltip>
                                </>
                            )}
                        <Tooltip title={constants.DELETE}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                )}
            </Stack>
        </SelectionBar>
    );
};

export default SelectedFileOptions;
