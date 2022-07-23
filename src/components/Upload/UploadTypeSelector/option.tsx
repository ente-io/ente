import React from 'react';
import { Button, ButtonProps } from '@mui/material';
import ChevronRight from '@mui/icons-material/ChevronRight';
import { FluidContainer } from 'components/Container';

type Iprops = ButtonProps<'button'>;

export function UploadTypeOption({ children, ...props }: Iprops) {
    return (
        <Button
            size="large"
            color="secondary"
            endIcon={<ChevronRight />}
            {...props}>
            <FluidContainer>{children}</FluidContainer>
        </Button>
    );
}
