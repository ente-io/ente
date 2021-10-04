import { SetDialogMessage } from 'components/MessageDialog';
import React from 'react';
import { SetCollectionSelectorAttributes } from './CollectionSelector';
import styled from 'styled-components';
import Navbar from 'components/Navbar';
import DeleteIcon from 'components/icons/DeleteIcon';
import CrossIcon from 'components/icons/CrossIcon';
import AddIcon from 'components/icons/AddIcon';
import { IconButton } from 'components/Container';
import constants from 'utils/strings/constants';
import Archive from 'components/icons/Archive';
import MoveIcon from 'components/icons/MoveIcon';
import { COLLECTION_OPS_TYPE } from 'utils/collection';
import { ALL_SECTION, ARCHIVE_SECTION, TRASH_SECTION } from './Collections';
import UnArchive from 'components/icons/UnArchive';
import { OverlayTrigger } from 'react-bootstrap';
import { Collection } from 'services/collectionService';
import RemoveIcon from 'components/icons/RemoveIcon';

interface Props {
    addToCollectionHelper: (collection: Collection) => void;
    moveToCollectionHelper: (collection: Collection) => void;
    showCreateCollectionModal: (opsType: COLLECTION_OPS_TYPE) => () => void;
    setDialogMessage: SetDialogMessage;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    deleteFileHelper: (permanent?: boolean) => void;
    removeFromCollectionHelper: () => void;
    count: number;
    clearSelection: () => void;
    archiveFilesHelper: () => void;
    unArchiveFilesHelper: () => void;
    activeCollection: number;
}

const SelectionBar = styled(Navbar)`
    position: fixed;
    top: 0;
    color: #fff;
    z-index: 1001;
    width: 100%;
    padding: 0 16px;
`;

const SelectionContainer = styled.div`
    flex: 1;
    align-items: center;
    display: flex;
`;

export const IconWithMessage = (props) => (
    <OverlayTrigger
        placement="bottom"
        overlay={<p style={{ zIndex: 1002 }}>{props.message}</p>}>
        {props.children}
    </OverlayTrigger>
);

const SelectedFileOptions = ({
    addToCollectionHelper,
    moveToCollectionHelper,
    showCreateCollectionModal,
    removeFromCollectionHelper,
    setDialogMessage,
    setCollectionSelectorAttributes,
    deleteFileHelper,
    count,
    clearSelection,
    archiveFilesHelper,
    unArchiveFilesHelper,
    activeCollection,
}: Props) => {
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
            staticBackdrop: true,
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
            staticBackdrop: true,
            proceed: {
                action: () => deleteFileHelper(true),
                text: constants.DELETE,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });

    const removeFromCollectionHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_REMOVE,
            content: constants.CONFIRM_REMOVE_MESSAGE,
            staticBackdrop: true,
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
            <SelectionContainer>
                <IconButton onClick={clearSelection}>
                    <CrossIcon />
                </IconButton>
                <div>
                    {count} {constants.SELECTED}
                </div>
            </SelectionContainer>
            {activeCollection === ARCHIVE_SECTION ? (
                <IconWithMessage message={constants.UNARCHIVE}>
                    <IconButton onClick={unArchiveFilesHelper}>
                        <UnArchive />
                    </IconButton>
                </IconWithMessage>
            ) : activeCollection === TRASH_SECTION ? (
                <IconWithMessage message={constants.DELETE_PERMANENTLY}>
                    <IconButton onClick={permanentlyDeleteHandler}>
                        <DeleteIcon />
                    </IconButton>
                </IconWithMessage>
            ) : (
                <>
                    {activeCollection === ALL_SECTION && (
                        <IconWithMessage message={constants.ARCHIVE}>
                            <IconButton onClick={archiveFilesHelper}>
                                <Archive />
                            </IconButton>
                        </IconWithMessage>
                    )}
                    {activeCollection !== ALL_SECTION && (
                        <IconWithMessage message={constants.MOVE}>
                            <IconButton onClick={moveToCollection}>
                                <MoveIcon />
                            </IconButton>
                        </IconWithMessage>
                    )}
                    <IconWithMessage message={constants.ADD}>
                        <IconButton onClick={addToCollection}>
                            <AddIcon />
                        </IconButton>
                    </IconWithMessage>
                    {activeCollection !== ALL_SECTION && (
                        <IconWithMessage message={constants.REMOVE}>
                            <IconButton onClick={removeFromCollectionHandler}>
                                <RemoveIcon />
                            </IconButton>
                        </IconWithMessage>
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
