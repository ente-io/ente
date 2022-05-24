import React from 'react';
import CloseFullscreenIcon from '@mui/icons-material/CloseFullscreen';

export function MinimizeIcon() {
    return (
        <CloseFullscreenIcon
            sx={{
                padding: '4px',
                transform: 'rotate(90deg)',
            }}
        />
    );
}
