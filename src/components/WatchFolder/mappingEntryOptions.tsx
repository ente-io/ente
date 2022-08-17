import React from 'react';
import constants from 'utils/strings/constants';
import DoNotDisturbOutlinedIcon from '@mui/icons-material/DoNotDisturbOutlined';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import OverflowMenu from 'components/OverflowMenu/menu';
import { OverflowMenuOption } from 'components/OverflowMenu/option';

interface Iprops {
    confirmStopWatching: () => void;
}

export default function MappingEntryOptions({ confirmStopWatching }: Iprops) {
    return (
        <OverflowMenu
            ariaControls={'watch-mapping-option'}
            triggerButtonIcon={<MoreHorizIcon />}>
            <OverflowMenuOption
                color="danger"
                onClick={confirmStopWatching}
                startIcon={<DoNotDisturbOutlinedIcon />}>
                {constants.STOP_WATCHING}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
