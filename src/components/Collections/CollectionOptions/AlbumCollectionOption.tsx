import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';

import EditIcon from '@mui/icons-material/Edit';
import PeopleIcon from '@mui/icons-material/People';
import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import { CollectionActions } from '.';
import Unarchive from '@mui/icons-material/Unarchive';
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';
import { useTranslation } from 'react-i18next';

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
    const { t } = useTranslation();
    return (
        <>
            <OverflowMenuOption
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_RENAME_DIALOG,
                    false
                )}
                startIcon={<EditIcon />}>
                {t('RENAME_COLLECTION')}
            </OverflowMenuOption>
            {IsArchived ? (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.UNARCHIVE
                    )}
                    startIcon={<Unarchive />}>
                    {t('UNARCHIVE_COLLECTION')}
                </OverflowMenuOption>
            ) : (
                <OverflowMenuOption
                    onClick={handleCollectionAction(CollectionActions.ARCHIVE)}
                    startIcon={<ArchiveOutlined />}>
                    {t('ARCHIVE_COLLECTION')}
                </OverflowMenuOption>
            )}
            <OverflowMenuOption
                startIcon={<DeleteOutlinedIcon />}
                onClick={handleCollectionAction(
                    CollectionActions.CONFIRM_DELETE,
                    false
                )}>
                {t('DELETE_COLLECTION')}
            </OverflowMenuOption>
            <OverflowMenuOption
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_SHARE_DIALOG,
                    false
                )}
                startIcon={<PeopleIcon />}>
                {t('SHARE_COLLECTION')}
            </OverflowMenuOption>
        </>
    );
}
