import { MenuItem, ButtonProps, Typography, Box } from '@mui/material';
import { FluidContainer } from 'components/Container';
import { DotSeparator } from 'components/Sidebar/styledComponents';
import { OverflowMenuContext } from 'contexts/overflowMenu';
import React, { useContext } from 'react';

interface Iprops {
    onClick: () => void;
    color?: ButtonProps['color'];
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    subText?: string;
    keepOpenAfterClick?: boolean;
    children?: any;
}
export function EnteMenuItem({
    onClick,
    color = 'primary',
    startIcon,
    endIcon,
    subText,
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
                <Typography variant="button">{children}</Typography>
            </FluidContainer>
            {subText && (
                <FluidContainer
                    sx={{
                        color: 'text.secondary',
                        fontSize: '14px',
                    }}>
                    <DotSeparator style={{ fontSize: 8 }} />

                    {subText}
                </FluidContainer>
            )}
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
