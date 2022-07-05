import React from 'react';
import { Button } from '@mui/material';
import ChevronRight from '@mui/icons-material/ChevronRight';
import { FluidContainer } from 'components/Container';

export function UploadTypeOption({ uploadFunc, Icon, uploadName }) {
    return (
        <Button
            size="large"
            onClick={uploadFunc}
            color="secondary"
            startIcon={<Icon />}
            endIcon={<ChevronRight />}>
            <FluidContainer>{uploadName}</FluidContainer>
        </Button>
    );
}
