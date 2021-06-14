import { SetDialogMessage } from 'components/MessageDialog';
import React from 'react';
import { SetCollectionSelectorAttributes } from './CollectionSelector';
import styled from 'styled-components';
import Navbar from 'components/Navbar';
import DeleteIcon from 'components/icons/DeleteIcon';
import CrossIcon from 'components/icons/CrossIcon';
import AddIcon from 'components/icons/AddIcon';
import { IconButton } from 'components/Container';
import constants from 'utils/strings/englishConstants';

interface Props {
    addToCollectionHelper: (collectionName, collection) => void;
    showCreateCollectionModal: () => void;
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
    showCreateCollectionModal,
    setDialogMessage,
    setCollectionSelectorAttributes,
    deleteFileHelper,
    count,
    clearSelection,
}: Props) => {
    const addToCollection = () => setCollectionSelectorAttributes({
        callback: (collection) => addToCollectionHelper(null, collection),
        showNextModal: showCreateCollectionModal,
        title: constants.ADD_TO_COLLECTION,
    });

    const deleteHandler = () => setDialogMessage({
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

    return (
        <SelectionBar>
            <SelectionContainer>
                <IconButton onClick={clearSelection}><CrossIcon /></IconButton>
                <div>{count} {constants.SELECTED}</div>
            </SelectionContainer>
            <IconButton onClick={addToCollection}><AddIcon /></IconButton>
            <IconButton onClick={deleteHandler}><DeleteIcon /></IconButton>
        </SelectionBar>
    );
};

export default SelectedFileOptions;
