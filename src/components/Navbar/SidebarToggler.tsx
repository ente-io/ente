import React from 'react';
import MenuIcon from '@mui/icons-material/Menu';
import IconButton from '@mui/material/IconButton';

export default function SidebarToggler({ openSidebar }) {
    return (
        <IconButton onClick={openSidebar}>
            <MenuIcon />
        </IconButton>
    );
}
