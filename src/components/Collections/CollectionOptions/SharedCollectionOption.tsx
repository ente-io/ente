import { OverflowMenuOption } from 'components/OverflowMenu/option';
import React from 'react';
import LogoutIcon from '@mui/icons-material/Logout';
import { CollectionActions } from '.';
import { useTranslation } from 'react-i18next';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function SharedCollectionOption({ handleCollectionAction }: Iprops) {
    const { t } = useTranslation();
    return (
        <OverflowMenuOption
            startIcon={<LogoutIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_LEAVE_SHARED_ALBUM,
                false
            )}>
            {t('LEAVE_ALBUM')}
        </OverflowMenuOption>
    );
}
