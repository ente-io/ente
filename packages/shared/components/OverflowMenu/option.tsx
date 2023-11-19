import { MenuItem, ButtonProps, Typography, Box } from '@mui/material';
import { FluidContainer } from '@ente/shared/components/Container';
import { OverflowMenuContext } from './context';
import React, { useContext } from 'react';

interface Iprops {
    onClick: () => void;
    color?: ButtonProps['color'];
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    keepOpenAfterClick?: boolean;
    children?: any;
}
export function OverflowMenuOption({
    onClick,
    color = 'primary',
    startIcon,
    endIcon,
    keepOpenAfterClick,
    children,
}: Iprops) {
    const menuContext = useContext(OverflowMenuContext);

    const handleClick = () => {
        onClick();
        if (!keepOpenAfterClick) {
            menuContext.close();
        }
    };
    return (
        <MenuItem
            onClick={handleClick}
            sx={{
                minWidth: 220,
                color: (theme) => theme.palette[color].main,
                padding: 1.5,
                '& .MuiSvgIcon-root': {
                    fontSize: '20px',
                },
            }}>
            <FluidContainer>
                {startIcon && (
                    <Box
                        sx={{
                            padding: 0,
                            marginRight: 1.5,
                        }}>
                        {startIcon}
                    </Box>
                )}
                <Typography fontWeight="bold">{children}</Typography>
            </FluidContainer>
            {endIcon && (
                <Box
                    sx={{
                        padding: 0,
                        marginLeft: 1,
                    }}>
                    {endIcon}
                </Box>
            )}
        </MenuItem>
    );
}
