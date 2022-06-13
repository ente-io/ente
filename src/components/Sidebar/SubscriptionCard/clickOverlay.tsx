import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { Overlay } from 'components/Container';
import React from 'react';
export function ClickOverlay(openPlanSelector) {
    return (
        <Overlay
            onClick={openPlanSelector}
            zIndex={2}
            justifyContent={'flex-end'}
            alignItems="center"
            sx={{ cursor: 'pointer' }}>
            <ChevronRightIcon />
        </Overlay>
    );
}
