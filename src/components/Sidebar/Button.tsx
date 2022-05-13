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
        <Button
            variant="text"
            fullWidth
            sx={{ mb: 1, px: 1, py: '10px', ...sx }}
            css={`
                font-size: 16px;
                font-weight: 600;
                line-height: 24px;
            `}
            {...props}>
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
