import React, { useState } from 'react';
import Menu from '@mui/material/Menu';
import { IconButton, styled } from '@mui/material';
import { OverflowMenuContext } from 'contexts/overflowMenu';

export interface Iprops {
    menuTriggerIcon: React.ReactNode;
    children?: React.ReactNode;
    ariaControls: string;
}

const StyledMenu = styled(Menu)`
    & .MuiPaper-root {
        box-shadow: 0px 0px 6px rgba(0, 0, 0, 0.16),
            0px 3px 6px rgba(0, 0, 0, 0.12);
    }
    & .MuiList-root {
        padding: 0;
        border: none;
    }
`;

export default function OverflowMenu({
    children,
    ariaControls,
    menuTriggerIcon,
}: Iprops) {
    const [sortByEl, setSortByEl] = useState(null);
    const handleClose = () => setSortByEl(null);
    return (
        <OverflowMenuContext.Provider value={{ close: handleClose }}>
            <IconButton
                onClick={(event) => setSortByEl(event.currentTarget)}
                aria-controls={sortByEl ? ariaControls : undefined}
                aria-haspopup="true"
                aria-expanded={sortByEl ? 'true' : undefined}>
                {menuTriggerIcon}
            </IconButton>
            <StyledMenu
                id={ariaControls}
                anchorEl={sortByEl}
                open={Boolean(sortByEl)}
                onClose={handleClose}
                MenuListProps={{
                    disablePadding: true,
                    'aria-labelledby': ariaControls,
                }}
                anchorOrigin={{
                    vertical: 'bottom',
                    horizontal: 'center',
                }}
                transformOrigin={{
                    vertical: 'center',
                    horizontal: 'right',
                }}>
                {children}
            </StyledMenu>
        </OverflowMenuContext.Provider>
    );
}
