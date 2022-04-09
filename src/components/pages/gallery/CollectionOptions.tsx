import React from 'react';
import { SetDialogMessage } from 'components/MessageDialog';
import { ListGroup, Popover } from 'react-bootstrap';
import { deleteCollection, renameCollection } from 'services/collectionService';
import { downloadCollection, getSelectedCollection } from 'utils/collection';
import constants from 'utils/strings/constants';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import LinkButton, { ButtonVariant, LinkButtonProps } from './LinkButton';
import { sleep } from 'utils/common';
import { Collection } from 'types/collection';
import { IsArchived } from 'utils/magicMetadata';

interface CollectionOptionsProps {
    syncWithRemote: () => Promise<void>;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    collections: Collection[];
    selectedCollectionID: number;
    setDialogMessage: SetDialogMessage;
    startLoading: () => void;
    finishLoading: () => void;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
}

export const MenuLink = ({ children, ...props }: LinkButtonProps) => (
    <LinkButton
        style={{ fontSize: '14px', fontWeight: 700, padding: '8px 1em' }}
        {...props}>
        {children}
    </LinkButton>
);

export const MenuItem = (props: { children: any }) => (
    <ListGroup.Item
        style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: '#282828',
            padding: 0,
        }}>
        {props.children}
    </ListGroup.Item>
);

const CollectionOptions = (props: CollectionOptionsProps) => {
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
                props.selectedCollectionID,
                props.collections
            )?.name,
            callback: (newName) => {
                props.startLoading();
                collectionRename(
                    getSelectedCollection(
                        props.selectedCollectionID,
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
                        props.selectedCollectionID,
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

    const archivingNotAvailableOnWeb = () => {
        props.setDialogMessage({
            title: constants.CONFIRM_ARCHIVE_COLLECTION,
            content: constants.ARCHIVE_COLLECTION_MESSAGE(),
            staticBackdrop: true,
            close: {},
        });
    };

    const downloadCollectionHelper = async () => {
        props.startLoading();
        await downloadCollection(
            props.selectedCollectionID,
            props.setDialogMessage
        );
        await sleep(1000);
        props.finishLoading();
    };

    return (
        <Popover id="collection-options" style={{ borderRadius: '10px' }}>
            <Popover.Content style={{ padding: 0, border: 'none' }}>
                <ListGroup style={{ borderRadius: '8px' }}>
                    <MenuItem>
                        <MenuLink onClick={showRenameCollectionModal}>
                            {constants.RENAME}
                        </MenuLink>
                    </MenuItem>
                    <MenuItem>
                        <MenuLink onClick={props.showCollectionShareModal}>
                            {constants.SHARE}
                        </MenuLink>
                    </MenuItem>
                    <MenuItem>
                        <MenuLink onClick={confirmDownloadCollection}>
                            {constants.DOWNLOAD}
                        </MenuLink>
                    </MenuItem>
                    <MenuItem>
                        <MenuLink onClick={archivingNotAvailableOnWeb}>
                            {IsArchived(
                                getSelectedCollection(
                                    props.selectedCollectionID,
                                    props.collections
                                )
                            )
                                ? constants.ARCHIVE
                                : constants.UNARCHIVE}
                        </MenuLink>
                    </MenuItem>
                    <MenuItem>
                        <MenuLink
                            variant={ButtonVariant.danger}
                            onClick={confirmDeleteCollection}>
                            {constants.DELETE}
                        </MenuLink>
                    </MenuItem>
                </ListGroup>
            </Popover.Content>
        </Popover>
    );
};

export default CollectionOptions;
