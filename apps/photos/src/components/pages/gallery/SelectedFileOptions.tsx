import React, { useContext } from 'react';
import { SetCollectionSelectorAttributes } from 'types/gallery';
import { FluidContainer } from 'components/Container';
import { COLLECTION_OPS_TYPE } from 'utils/collection';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    HIDDEN_SECTION,
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
import { t } from 'i18next';
import { formatNumber } from 'utils/number/format';
import VisibilityOffOutlined from '@mui/icons-material/VisibilityOffOutlined';
import VisibilityOutlined from '@mui/icons-material/VisibilityOutlined';

interface Props {
    addToCollectionHelper: (collection: Collection) => void;
    moveToCollectionHelper: (collection: Collection) => void;
    restoreToCollectionHelper: (collection: Collection) => void;
    showCreateCollectionModal: (opsType: COLLECTION_OPS_TYPE) => () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    deleteFileHelper: (permanent?: boolean) => void;
    hideFilesHelper: () => void;
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
    isIncomingSharedCollection: boolean;
    isInSearchMode: boolean;
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
    hideFilesHelper,
    downloadHelper,
    count,
    ownCount,
    clearSelection,
    archiveFilesHelper,
    unArchiveFilesHelper,
    activeCollection,
    isFavoriteCollection,
    isUncategorizedCollection,
    isIncomingSharedCollection,
    isInSearchMode,
}: Props) => {
    const { setDialogMessage } = useContext(AppContext);
    const addToCollection = () =>
        setCollectionSelectorAttributes({
            callback: addToCollectionHelper,
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.ADD),
            title: t('ADD_TO_COLLECTION'),
            fromCollection: activeCollection,
        });

    const trashHandler = () =>
        setDialogMessage(getTrashFilesMessage(deleteFileHelper));

    const permanentlyDeleteHandler = () =>
        setDialogMessage({
            title: t('DELETE_FILES_TITLE'),
            content: t('DELETE_FILES_MESSAGE'),
            proceed: {
                action: () => deleteFileHelper(true),
                text: t('DELETE'),
                variant: 'critical',
            },
            close: { text: t('CANCEL') },
        });

    const restoreHandler = () =>
        setCollectionSelectorAttributes({
            callback: restoreToCollectionHelper,
            showNextModal: showCreateCollectionModal(
                COLLECTION_OPS_TYPE.RESTORE
            ),
            title: t('RESTORE_TO_COLLECTION'),
        });

    const removeFromCollectionHandler = () => {
        if (ownCount === count) {
            setDialogMessage({
                title: t('REMOVE_FROM_COLLECTION'),
                content: t('CONFIRM_SELF_REMOVE_MESSAGE'),

                proceed: {
                    action: removeFromCollectionHelper,
                    text: t('YES_REMOVE'),
                    variant: 'primary',
                },
                close: { text: t('CANCEL') },
            });
        } else {
            setDialogMessage({
                title: t('REMOVE_FROM_COLLECTION'),
                content: t('CONFIRM_SELF_AND_OTHER_REMOVE_MESSAGE'),

                proceed: {
                    action: removeFromCollectionHelper,
                    text: t('YES_REMOVE'),
                    variant: 'critical',
                },
                close: { text: t('CANCEL') },
            });
        }
    };

    const moveToCollection = () => {
        setCollectionSelectorAttributes({
            callback: moveToCollectionHelper,
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.MOVE),
            title: t('MOVE_TO_COLLECTION'),
            fromCollection: activeCollection,
        });
    };

    const unhideFileHelper = () => {
        setCollectionSelectorAttributes({
            callback: moveToCollectionHelper,
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.MOVE),
            title: t('UNHIDE_TO_COLLECTION'),
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
                    {formatNumber(count)} {t('SELECTED')}{' '}
                    {ownCount !== count &&
                        `(${formatNumber(ownCount)} ${t('YOURS')})`}
                </Box>
            </FluidContainer>
            <Stack spacing={2} direction="row" mr={2}>
                {isInSearchMode ? (
                    <>
                        <Tooltip title={t('FIX_CREATION_TIME')}>
                            <IconButton onClick={fixTimeHelper}>
                                <ClockIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('DOWNLOAD')}>
                            <IconButton onClick={downloadHelper}>
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('ADD')}>
                            <IconButton onClick={addToCollection}>
                                <AddIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('ARCHIVE')}>
                            <IconButton onClick={archiveFilesHelper}>
                                <ArchiveIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('HIDE')}>
                            <IconButton onClick={hideFilesHelper}>
                                <VisibilityOffOutlined />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : activeCollection === TRASH_SECTION ? (
                    <>
                        <Tooltip title={t('RESTORE')}>
                            <IconButton onClick={restoreHandler}>
                                <RestoreIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('DELETE_PERMANENTLY')}>
                            <IconButton onClick={permanentlyDeleteHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : isUncategorizedCollection ? (
                    <>
                        <Tooltip title={t('DOWNLOAD')}>
                            <IconButton onClick={downloadHelper}>
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('MOVE')}>
                            <IconButton onClick={moveToCollection}>
                                <MoveIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('DELETE')}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : isIncomingSharedCollection ? (
                    <Tooltip title={t('DOWNLOAD')}>
                        <IconButton onClick={downloadHelper}>
                            <DownloadIcon />
                        </IconButton>
                    </Tooltip>
                ) : activeCollection === HIDDEN_SECTION ? (
                    <>
                        <Tooltip title={t('UNHIDE')}>
                            <IconButton onClick={unhideFileHelper}>
                                <VisibilityOutlined />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('DOWNLOAD')}>
                            <IconButton onClick={downloadHelper}>
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>

                        <Tooltip title={t('DELETE')}>
                            <IconButton onClick={trashHandler}>
                                <DeleteIcon />
                            </IconButton>
                        </Tooltip>
                    </>
                ) : (
                    <>
                        <Tooltip title={t('FIX_CREATION_TIME')}>
                            <IconButton onClick={fixTimeHelper}>
                                <ClockIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('DOWNLOAD')}>
                            <IconButton onClick={downloadHelper}>
                                <DownloadIcon />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('ADD')}>
                            <IconButton onClick={addToCollection}>
                                <AddIcon />
                            </IconButton>
                        </Tooltip>
                        {activeCollection === ARCHIVE_SECTION && (
                            <Tooltip title={t('UNARCHIVE')}>
                                <IconButton onClick={unArchiveFilesHelper}>
                                    <UnArchiveIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                        {activeCollection === ALL_SECTION && (
                            <Tooltip title={t('ARCHIVE')}>
                                <IconButton onClick={archiveFilesHelper}>
                                    <ArchiveIcon />
                                </IconButton>
                            </Tooltip>
                        )}
                        {activeCollection !== ALL_SECTION &&
                            activeCollection !== ARCHIVE_SECTION &&
                            !isFavoriteCollection && (
                                <>
                                    <Tooltip title={t('MOVE')}>
                                        <IconButton onClick={moveToCollection}>
                                            <MoveIcon />
                                        </IconButton>
                                    </Tooltip>

                                    <Tooltip title={t('REMOVE')}>
                                        <IconButton
                                            onClick={
                                                removeFromCollectionHandler
                                            }>
                                            <RemoveIcon />
                                        </IconButton>
                                    </Tooltip>
                                </>
                            )}
                        <Tooltip title={t('HIDE')}>
                            <IconButton onClick={hideFilesHelper}>
                                <VisibilityOffOutlined />
                            </IconButton>
                        </Tooltip>
                        <Tooltip title={t('DELETE')}>
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
