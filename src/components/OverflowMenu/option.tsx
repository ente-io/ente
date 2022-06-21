import { MenuItem, ListItemIcon, ButtonProps, Typography } from '@mui/material';
import React from 'react';

interface Iprops {
    onClick: () => void;
    color?: ButtonProps['color'];
    startIcon?: React.ReactNode;
    children?: any;
}
export function OverflowMenuOption({
    onClick,
    color = 'primary',
    startIcon,
    children,
}: Iprops) {
    return (
        <MenuItem
            onClick={onClick}
            sx={{
                color: (theme) => theme.palette[color].main,
                padding: '12px',
            }}>
            {startIcon && (
                <ListItemIcon
                    sx={{
                        color: 'inherit',
                        padding: '0',
                        paddingRight: '12px',
                        fontSize: '20px',
                    }}>
                    {startIcon}
                </ListItemIcon>
            )}
            <Typography variant="button">{children}</Typography>
        </MenuItem>
    );
}
