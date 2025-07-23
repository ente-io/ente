import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import {
    IconButton,
    MenuItem,
    Stack,
    Typography,
    type IconButtonProps,
    type PaperProps,
} from "@mui/material";
import Menu, { type MenuProps } from "@mui/material/Menu";
import React, { createContext, useContext, useMemo, useState } from "react";

interface OverflowMenuContextT {
    close: () => void;
}

const OverflowMenuContext = createContext<OverflowMenuContextT | undefined>(
    undefined,
);

interface OverflowMenuProps {
    /**
     * An ARIA identifier for the overflow menu when it is displayed.
     */
    ariaID: string;
    /**
     * The icon for the trigger button.
     *
     * If not provided, then by default the MoreHoriz icon from MUI is used.
     */
    triggerButtonIcon?: React.ReactNode;
    /**
     * Optional additional properties for the trigger icon button.
     */
    triggerButtonSxProps?: IconButtonProps["sx"];
    /**
     * Optional additional sx props for the MUI {@link Paper} that underlies the
     * {@link Menu}.
     */
    menuPaperSxProps?: PaperProps["sx"];
}

/**
 * An overflow menu showing {@link OverflowMenuOptions}, alongwith a button to
 * trigger the visibility of the menu.
 */
export const OverflowMenu: React.FC<
    React.PropsWithChildren<OverflowMenuProps>
> = ({
    ariaID,
    triggerButtonIcon,
    triggerButtonSxProps,
    menuPaperSxProps,
    children,
}) => {
    const [anchorEl, setAnchorEl] = useState<MenuProps["anchorEl"]>();
    const context = useMemo(
        () => ({ close: () => setAnchorEl(undefined) }),
        [],
    );
    return (
        <OverflowMenuContext value={context}>
            <IconButton
                onClick={(event) => setAnchorEl(event.currentTarget)}
                aria-controls={anchorEl ? ariaID : undefined}
                aria-haspopup="true"
                aria-expanded={anchorEl ? "true" : undefined}
                sx={triggerButtonSxProps}
            >
                {triggerButtonIcon ?? <MoreHorizIcon />}
            </IconButton>
            <Menu
                id={ariaID}
                {...(anchorEl && { anchorEl })}
                open={!!anchorEl}
                onClose={() => setAnchorEl(undefined)}
                slotProps={{
                    paper: { sx: menuPaperSxProps },
                    list: {
                        // Disable padding at the top and bottom of the menu list.
                        disablePadding: true,
                        "aria-labelledby": ariaID,
                    },
                }}
                anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
                transformOrigin={{ vertical: "top", horizontal: "right" }}
            >
                {children}
            </Menu>
        </OverflowMenuContext>
    );
};

interface OverflowMenuOptionProps {
    /**
     * Called when the menu option is clicked.
     */
    onClick: () => void;
    /**
     * The color of the text and icons.
     *
     * Default: "primary".
     */
    color?: "primary" | "critical";
    /**
     * An optional icon to show at the leading edge of the menu option.
     */
    startIcon?: React.ReactNode;
    /**
     * An optional icon to show at the trailing edge of the menu option.
     */
    endIcon?: React.ReactNode;
}

/**
 * Individual options meant to be shown inside an {@link OverflowMenu}.
 */
export const OverflowMenuOption: React.FC<
    React.PropsWithChildren<OverflowMenuOptionProps>
> = ({ onClick, color = "primary", startIcon, endIcon, children }) => {
    const menuContext = useContext(OverflowMenuContext);

    const handleClick = () => {
        onClick();
        // We might've already been closed as a result of our containing menu
        // getting closed. An example of this is the "Sort by" option in the
        // album options overflow menu, where the `onClick` above will result in
        // `onClose` being called on our parent menu, so `menuContext` will be
        // undefined when we get here.
        menuContext?.close();
    };

    return (
        <MenuItem
            onClick={handleClick}
            sx={(theme) => ({
                minWidth: 220,
                color: theme.vars.palette[color].main,
                // Reduce the size of the icons a bit to make it fit better with
                // the text.
                "& .MuiSvgIcon-root": { fontSize: "20px" },
            })}
        >
            <Stack
                direction="row"
                sx={{
                    gap: 1.5,
                    alignItems: "center",
                    // Fill our container.
                    width: "100%",
                    // MUI has responsive padding, use a static value instead.
                    py: 1,
                }}
            >
                {startIcon}
                <Typography sx={{ flex: 1, fontWeight: "medium" }}>
                    {children}
                </Typography>
                {endIcon}
            </Stack>
        </MenuItem>
    );
};
