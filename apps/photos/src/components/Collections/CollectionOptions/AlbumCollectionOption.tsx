import { OverflowMenuOption } from '@ente/shared/components/OverflowMenu/option';
import React from 'react';

import EditIcon from '@mui/icons-material/Edit';
import PeopleIcon from '@mui/icons-material/People';
import DeleteOutlinedIcon from '@mui/icons-material/DeleteOutlined';
import { CollectionActions } from '.';
import Unarchive from '@mui/icons-material/Unarchive';
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';
import SortIcon from '@mui/icons-material/Sort';
import { t } from 'i18next';
import PushPinOutlined from '@mui/icons-material/PushPinOutlined';
import { UnPinIcon } from 'components/icons/UnPinIcon';
import VisibilityOffOutlined from '@mui/icons-material/VisibilityOffOutlined';
import VisibilityOutlined from '@mui/icons-material/VisibilityOutlined';
import TvIcon from '@mui/icons-material/Tv';

interface Iprops {
    isArchived: boolean;
    isPinned: boolean;
    isHidden: boolean;
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function AlbumCollectionOption({
    isArchived,
    isPinned,
    isHidden,
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
                {t('RENAME_COLLECTION')}
            </OverflowMenuOption>
            <OverflowMenuOption
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_SORT_ORDER_MENU,
                    false
                )}
                startIcon={<SortIcon />}>
                {t('SORT_BY')}
            </OverflowMenuOption>
            {isPinned ? (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.UNPIN,
                        false
                    )}
                    startIcon={<UnPinIcon />}>
                    {t('UNPIN_ALBUM')}
                </OverflowMenuOption>
            ) : (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.PIN,
                        false
                    )}
                    startIcon={<PushPinOutlined />}>
                    {t('PIN_ALBUM')}
                </OverflowMenuOption>
            )}
            {!isHidden && (
                <>
                    {isArchived ? (
                        <OverflowMenuOption
                            onClick={handleCollectionAction(
                                CollectionActions.UNARCHIVE
                            )}
                            startIcon={<Unarchive />}>
                            {t('UNARCHIVE_COLLECTION')}
                        </OverflowMenuOption>
                    ) : (
                        <OverflowMenuOption
                            onClick={handleCollectionAction(
                                CollectionActions.ARCHIVE
                            )}
                            startIcon={<ArchiveOutlined />}>
                            {t('ARCHIVE_COLLECTION')}
                        </OverflowMenuOption>
                    )}
                </>
            )}
            {isHidden ? (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.UNHIDE,
                        false
                    )}
                    startIcon={<VisibilityOutlined />}>
                    {t('UNHIDE_COLLECTION')}
                </OverflowMenuOption>
            ) : (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.HIDE,
                        false
                    )}
                    startIcon={<VisibilityOffOutlined />}>
                    {t('HIDE_COLLECTION')}
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
            <OverflowMenuOption
                startIcon={<TvIcon />}
                onClick={handleCollectionAction(
                    CollectionActions.SHOW_ALBUM_CAST_DIALOG,
                    false
                )}>
                {t('CAST_ALBUM_TO_TV')}
            </OverflowMenuOption>
        </>
    );
}
