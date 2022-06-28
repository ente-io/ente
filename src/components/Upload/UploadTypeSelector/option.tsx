import React from 'react';
import { Box } from '@mui/material';
import SidebarButton from 'components/Sidebar/Button';

export function UploadTypeOption({ uploadFunc, Icon, uploadName }) {
    return (
        <SidebarButton
            onClick={uploadFunc}
            color="secondary"
            variant="contained"
            sx={{ mb: 1, p: 2 }}>
            <Icon sx={{ mr: 2 }} />
            <Box flex="1" textAlign={'left'}>
                {uploadName}
            </Box>
        </SidebarButton>
    );
}
