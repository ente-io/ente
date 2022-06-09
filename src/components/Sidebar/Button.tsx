import React, { FC } from 'react';
import { Button, ButtonProps } from '@mui/material';
import { FluidContainer } from 'components/Container';

const SidebarButton: FC<ButtonProps<'button'>> = ({
    children,
    sx,
    ...props
}) => {
    return (
        <Button
            variant="text"
            fullWidth
            sx={{ my: 0.5, px: 1, py: '10px', ...sx }}
            css={`
                font-size: 16px;
                font-weight: 600;
                line-height: 24px;
                letter-spacing: 0em;
            `}
            {...props}>
            <FluidContainer>{children}</FluidContainer>
        </Button>
    );
};

export default SidebarButton;
