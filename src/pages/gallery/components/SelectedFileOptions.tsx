import AddToCollectionBtn from 'components/AddToCollectionBtn';
import DeleteBtn from 'components/DeleteBtn';
import { SetDialogMessage } from 'components/MessageDialog';
import React from 'react';
import constants from 'utils/strings/constants';
import { SetCollectionSelectorAttributes } from './CollectionSelector';

interface Props {
    addToCollectionHelper: (collectionName, collection) => Promise<void>;
    showCreateCollectionModal: () => void;
    setDialogMessage: SetDialogMessage;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    deleteFileHelper: () => Promise<void>;
}
const SelectedFileOptions = ({
    addToCollectionHelper,
    showCreateCollectionModal,
    setDialogMessage,
    setCollectionSelectorAttributes,
    deleteFileHelper,
}: Props) => {
    return (
        <>
            <AddToCollectionBtn
                onClick={() =>
                    setCollectionSelectorAttributes({
                        callback: (collection) =>
                            addToCollectionHelper(null, collection),
                        showNextModal: showCreateCollectionModal,
                        title: 'add to collection',
                    })
                }
            />
            <DeleteBtn
                onClick={() =>
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
                    })
                }
            />
        </>
    );
};

export default SelectedFileOptions;
