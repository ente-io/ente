import React from 'react';
import MenuIcon from '@mui/icons-material/Menu';
import { IconButton } from 'components/Container';

export default function SidebarToggler({ openSidebar }) {
    return (
        <IconButton onClick={openSidebar}>
            <MenuIcon />
        </IconButton>
    );
}
