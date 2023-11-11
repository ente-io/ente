import React from 'react';
import { t } from 'i18next';

import DoNotDisturbOutlinedIcon from '@mui/icons-material/DoNotDisturbOutlined';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import OverflowMenu from '@ente/shared/components/OverflowMenu/menu';
import { OverflowMenuOption } from '@ente/shared/components/OverflowMenu/option';

interface Iprops {
    confirmStopWatching: () => void;
}

export default function MappingEntryOptions({ confirmStopWatching }: Iprops) {
    return (
        <OverflowMenu
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        theme.colors.background.elevated2,
                },
            }}
            ariaControls={'watch-mapping-option'}
            triggerButtonIcon={<MoreHorizIcon />}>
            <OverflowMenuOption
                color="critical"
                onClick={confirmStopWatching}
                startIcon={<DoNotDisturbOutlinedIcon />}>
                {t('STOP_WATCHING')}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
