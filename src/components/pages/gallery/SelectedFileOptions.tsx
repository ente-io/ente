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
import MoveIcon from 'components/icons/MoveIcon';
import { COLLECTION_OPS_TYPE } from 'utils/collection';

interface Props {
    addToCollectionHelper: (collectionName, collection) => void;
    moveToCollectionHelper: (collectionName, collection) => void;
    showCreateCollectionModal: (opsType: COLLECTION_OPS_TYPE) => () => void;
    setDialogMessage: SetDialogMessage;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    deleteFileHelper: () => void;
    count: number;
    clearSelection: () => void;
}

const SelectionBar = styled(Navbar)`
    position: fixed;
    top: 0;
    color: #fff;
    z-index: 1001;
    width: 100%;
`;

const SelectionContainer = styled.div`
    flex: 1;
    align-items: center;
    display: flex;
`;

const SelectedFileOptions = ({
    addToCollectionHelper,
    moveToCollectionHelper,
    showCreateCollectionModal,
    setDialogMessage,
    setCollectionSelectorAttributes,
    deleteFileHelper,
    count,
    clearSelection,
}: Props) => {
    const addToCollection = () =>
        setCollectionSelectorAttributes({
            callback: (collection) => addToCollectionHelper(null, collection),
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.ADD),
            title: constants.ADD_TO_COLLECTION,
        });

    const deleteHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_DELETE_FILE,
            content: constants.DELETE_FILE_MESSAGE,
            staticBackdrop: true,
            proceed: {
                action: deleteFileHelper,
                text: constants.DELETE,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });

    const moveToCollection = () => {
        setCollectionSelectorAttributes({
            callback: (collection) => moveToCollectionHelper(null, collection),
            showNextModal: showCreateCollectionModal(COLLECTION_OPS_TYPE.MOVE),
            title: constants.MOVE_TO_COLLECTION,
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
            <IconButton onClick={moveToCollection}>
                <MoveIcon />
            </IconButton>
            <IconButton onClick={addToCollection}>
                <AddIcon />
            </IconButton>
            <IconButton onClick={deleteHandler}>
                <DeleteIcon />
            </IconButton>
        </SelectionBar>
    );
};

export default SelectedFileOptions;
