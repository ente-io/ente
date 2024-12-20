import { FluidContainer } from "@ente/shared/components/Container";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import {
    Box,
    IconButton,
    MenuItem,
    styled,
    Typography,
    type ButtonProps,
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
    triggerButtonProps?: Partial<IconButtonProps>;
    /**
     * Optional additional properties for the MUI {@link Paper} that underlies
     * the {@link Menu}.
     */
    menuPaperProps?: Partial<PaperProps>;
}

/**
 * A custom MUI {@link Menu} with some Ente specific styling applied to it.
 */
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

/**
 * An overflow menu showing {@link OverflowMenuOptions}, alongwith a button to
 * trigger the visibility of the menu.
 */
export const OverflowMenu: React.FC<
    React.PropsWithChildren<OverflowMenuProps>
> = ({
    ariaID,
    triggerButtonIcon,
    triggerButtonProps,
    menuPaperProps,
    children,
}) => {
    const [anchorEl, setAnchorEl] = useState<MenuProps["anchorEl"]>();
    const context = useMemo(
        () => ({ close: () => setAnchorEl(undefined) }),
        [],
    );
    return (
        <OverflowMenuContext.Provider value={context}>
            <IconButton
                onClick={(event) => setAnchorEl(event.currentTarget)}
                aria-controls={anchorEl ? ariaID : undefined}
                aria-haspopup="true"
                aria-expanded={anchorEl ? "true" : undefined}
                {...triggerButtonProps}
            >
                {triggerButtonIcon ?? <MoreHorizIcon />}
            </IconButton>
            <StyledMenu
                id={ariaID}
                {...(anchorEl ? { anchorEl } : {})}
                open={!!anchorEl}
                onClose={() => setAnchorEl(undefined)}
                MenuListProps={{
                    disablePadding: true,
                    "aria-labelledby": ariaID,
                }}
                slotProps={{
                    paper: menuPaperProps,
                }}
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
};

interface OverflowMenuOptionProps {
    color?: ButtonProps["color"];
    /**
     * An optional icon to show at the leading edge of the menu option.
     */
    startIcon?: React.ReactNode;
    /**
     * An optional icon to show at the trailing edge of the menu option.
     */
    endIcon?: React.ReactNode;
    /**
     * Called when the menu option is clicked.
     */
    onClick: () => void;
}

export const OverflowMenuOption: React.FC<
    React.PropsWithChildren<OverflowMenuOptionProps>
> = ({ onClick, color = "primary", startIcon, endIcon, children }) => {
    const menuContext = useContext(OverflowMenuContext)!;

    const handleClick = () => {
        onClick();
        menuContext.close();
    };

    return (
        <MenuItem
            onClick={handleClick}
            sx={{
                minWidth: 220,
                color: (theme) => theme.palette[color].main,
                padding: 1.5,
                "& .MuiSvgIcon-root": {
                    fontSize: "20px",
                },
            }}
        >
            <FluidContainer>
                {startIcon && (
                    <Box
                        sx={{
                            padding: 0,
                            marginBlockStart: "6px",
                            marginRight: 1.5,
                        }}
                    >
                        {startIcon}
                    </Box>
                )}
                <Typography fontWeight="bold">{children}</Typography>
            </FluidContainer>
            {endIcon && (
                <Box
                    sx={{
                        padding: 0,
                        marginLeft: 1,
                    }}
                >
                    {endIcon}
                </Box>
            )}
        </MenuItem>
    );
};
