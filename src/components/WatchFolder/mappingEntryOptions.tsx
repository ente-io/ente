import { IconButton, Menu, MenuItem } from '@mui/material';
import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import DoNotDisturbOutlinedIcon from '@mui/icons-material/DoNotDisturbOutlined';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';

export default function MappingEntryOptions({ confirmStopWatching }) {
    const [anchorEl, setAnchorEl] = useState(null);
    const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
        setAnchorEl(event.currentTarget);
    };
    const handleClose = () => {
        setAnchorEl(null);
    };

    const open = Boolean(anchorEl);
    return (
        <>
            <IconButton onClick={handleClick}>
                <MoreHorizIcon />
            </IconButton>
            <Menu
                id="basic-menu"
                anchorEl={anchorEl}
                open={open}
                onClose={handleClose}
                MenuListProps={{
                    'aria-labelledby': 'basic-button',
                }}
                anchorOrigin={{
                    vertical: 'bottom',
                    horizontal: 'center',
                }}
                transformOrigin={{
                    vertical: 'center',
                    horizontal: 'right',
                }}>
                <MenuItem
                    onClick={confirmStopWatching}
                    sx={{
                        fontWeight: 600,
                        color: (theme) => theme.palette.danger.main,
                    }}>
                    <span
                        style={{
                            marginRight: '6px',
                        }}>
                        <DoNotDisturbOutlinedIcon />
                    </span>
                    {constants.STOP_WATCHING}
                </MenuItem>
            </Menu>
        </>
    );
}
