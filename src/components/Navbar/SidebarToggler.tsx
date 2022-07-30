import React from 'react';
import MenuIcon from '@mui/icons-material/Menu';
import IconButton from '@mui/material/IconButton';

interface Iprops {
    openSidebar: () => void;
}
export default function SidebarToggler({ openSidebar }: Iprops) {
    return (
        <IconButton onClick={openSidebar}>
            <MenuIcon />
        </IconButton>
    );
}
