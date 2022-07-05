import ChevronRight from '@mui/icons-material/ChevronRight';
import { Button, ButtonProps } from '@mui/material';
import { FluidContainer } from 'components/Container';
import React from 'react';

const ManageSubscriptionButton = ({ children, ...props }: ButtonProps) => (
    <Button
        {...props}
        endIcon={<ChevronRight />}
        sx={{
            ...props.sx,
            justifyContent: 'flex-start',
        }}>
        <FluidContainer>{children}</FluidContainer>
    </Button>
);

export default ManageSubscriptionButton;
