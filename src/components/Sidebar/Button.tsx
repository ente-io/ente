import React, { FC } from 'react';
import { Button, ButtonProps } from '@mui/material';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import { FluidContainer } from 'components/Container';
interface IProps {
    hideArrow?: boolean;
    smallerArrow?: boolean;
}
const SidebarButton: FC<ButtonProps<'button', IProps>> = ({
    children,
    hideArrow,
    smallerArrow,
    sx,
    ...props
}) => {
    return (
        <Button variant="text" fullWidth sx={{ mb: 1, ...sx }} {...props}>
            <FluidContainer>{children}</FluidContainer>
            {!hideArrow && (
                <NavigateNextIcon
                    fontSize={smallerArrow ? 'small' : 'medium'}
                />
            )}
        </Button>
    );
};

export default SidebarButton;
