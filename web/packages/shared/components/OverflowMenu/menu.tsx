import { IconButton, PaperProps, styled } from "@mui/material";
import Menu from "@mui/material/Menu";
import React, { useState } from "react";
import { OverflowMenuContext } from "./context";

export interface Iprops {
    triggerButtonIcon: React.ReactNode;
    triggerButtonProps?: any;
    children?: React.ReactNode;
    ariaControls: string;
    menuPaperProps?: Partial<PaperProps>;
}

export const StyledMenu = styled(Menu)`
    & .MuiPaper-root {
        margin: 16px auto;
        box-shadow:
            0px 0px 6px rgba(0, 0, 0, 0.16),
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
    triggerButtonIcon,
    triggerButtonProps,
    menuPaperProps,
}: Iprops) {
    const [sortByEl, setSortByEl] = useState(null);
    const handleClose = () => setSortByEl(null);
    return (
        <OverflowMenuContext.Provider value={{ close: handleClose }}>
            <IconButton
                onClick={(event) => setSortByEl(event.currentTarget)}
                aria-controls={sortByEl ? ariaControls : undefined}
                aria-haspopup="true"
                aria-expanded={sortByEl ? "true" : undefined}
                {...triggerButtonProps}
            >
                {triggerButtonIcon}
            </IconButton>
            <StyledMenu
                id={ariaControls}
                anchorEl={sortByEl}
                open={Boolean(sortByEl)}
                onClose={handleClose}
                MenuListProps={{
                    disablePadding: true,
                    "aria-labelledby": ariaControls,
                }}
                PaperProps={menuPaperProps}
                anchorOrigin={{
                    vertical: "bottom",
                    horizontal: "right",
                }}
                transformOrigin={{
                    vertical: "top",
                    horizontal: "right",
                }}
            >
                {children}
            </StyledMenu>
        </OverflowMenuContext.Provider>
    );
}
