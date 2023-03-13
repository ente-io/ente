import React from 'react';
import { useTranslation } from 'react-i18next';

import DoNotDisturbOutlinedIcon from '@mui/icons-material/DoNotDisturbOutlined';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import OverflowMenu from 'components/OverflowMenu/menu';
import { OverflowMenuOption } from 'components/OverflowMenu/option';

interface Iprops {
    confirmStopWatching: () => void;
}

export default function MappingEntryOptions({ confirmStopWatching }: Iprops) {
    const { t } = useTranslation();

    return (
        <OverflowMenu
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        theme.palette.background.overPaper,
                },
            }}
            ariaControls={'watch-mapping-option'}
            triggerButtonIcon={<MoreHorizIcon />}>
            <OverflowMenuOption
                color="danger"
                onClick={confirmStopWatching}
                startIcon={<DoNotDisturbOutlinedIcon />}>
                {t('STOP_WATCHING')}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
