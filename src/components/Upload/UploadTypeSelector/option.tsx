import React from 'react';
import { Button } from '@mui/material';

export function UploadTypeOption({ uploadFunc, Icon, uploadName }) {
    return (
        <Button
            size="large"
            sx={{ justifyContent: 'flex-start' }}
            onClick={uploadFunc}
            color="secondary"
            startIcon={<Icon />}>
            {uploadName}
        </Button>
    );
}
