import React from 'react';
import OpenInFullIcon from '@mui/icons-material/OpenInFull';

export function MaximizeIcon() {
    return (
        <OpenInFullIcon
            sx={{
                padding: '4px',
                transform: 'rotate(90deg)',
            }}
        />
    );
}
