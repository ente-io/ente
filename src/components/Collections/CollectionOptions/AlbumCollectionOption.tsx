import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';

import EditIcon from '@mui/icons-material/Edit';
import PeopleIcon from '@mui/icons-material/People';
import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import constants from 'utils/strings/constants';
import { CollectionActions } from '.';
import Unarchive from '@mui/icons-material/Unarchive';
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';

interface Iprops {
    IsArchived: boolean;
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function AlbumCollectionOption({
    IsArchived,
    handleCollectionAction,
}: Iprops) {
    return (
        <>
            <OverflowMenuOption
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_RENAME_DIALOG,
                    false
                )}
                startIcon={<EditIcon />}>
                {constants.RENAME_COLLECTION}
            </OverflowMenuOption>
            {IsArchived ? (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.UNARCHIVE
                    )}
                    startIcon={<Unarchive />}>
                    {constants.UNARCHIVE_COLLECTION}
                </OverflowMenuOption>
            ) : (
                <OverflowMenuOption
                    onClick={handleCollectionAction(CollectionActions.ARCHIVE)}
                    startIcon={<ArchiveOutlined />}>
                    {constants.ARCHIVE_COLLECTION}
                </OverflowMenuOption>
            )}
            <OverflowMenuOption
                startIcon={<DeleteOutlinedIcon />}
                onClick={handleCollectionAction(
                    CollectionActions.CONFIRM_DELETE,
                    false
                )}>
                {constants.DELETE_COLLECTION}
            </OverflowMenuOption>
            <OverflowMenuOption
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_SHARE_DIALOG,
                    false
                )}
                startIcon={<PeopleIcon />}>
                {constants.SHARE_COLLECTION}
            </OverflowMenuOption>
        </>
    );
}
