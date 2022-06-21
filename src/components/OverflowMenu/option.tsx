import {
    MenuItem,
    ListItemIcon,
    ListItemText,
    ButtonProps,
} from '@mui/material';
import React from 'react';

interface Iprops {
    handleClick: () => void;
    color: ButtonProps['color'];
    startIcon: React.ReactNode;
    label: string;
}
export function OverflowMenuOption({
    handleClick,
    color,
    startIcon,
    label,
}: Iprops) {
    return (
        <MenuItem
            onClick={handleClick}
            sx={{
                color: (theme) => theme.palette[color].main,
                padding: '12px',
            }}>
            <ListItemIcon
                sx={{
                    color: 'inherit',
                    padding: '0',
                    paddingRight: '12px',
                    fontSize: '20px',
                }}>
                {startIcon}
            </ListItemIcon>
            <ListItemText>{label}</ListItemText>
        </MenuItem>
    );
}
