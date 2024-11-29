import { FluidContainer } from "@ente/shared/components/Container";
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

const OverflowMenuContext = createContext({
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    close: () => {},
});

interface OverflowMenuProps {
    /**
     * An ARIA identifier for the overflow menu when it is displayed.
     */
    ariaID: string;
    /**
     * The icon for the trigger button.
     */
    triggerButtonIcon: React.ReactNode;
    /**
     * Optional additional properties for the trigger icon button.
     */
    triggerButtonProps?: Partial<IconButtonProps>;
    // backgroundColor;
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
                {triggerButtonIcon}
            </IconButton>
            <StyledMenu
                id={ariaID}
                anchorEl={anchorEl}
                open={!!anchorEl}
                onClose={() => setAnchorEl(undefined)}
                MenuListProps={{
                    disablePadding: true,
                    "aria-labelledby": ariaID,
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
};

interface OverflowMenuOptionProps {
    onClick: () => void;
    color?: ButtonProps["color"];
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    children?: any;
    // To avoid changing old places without an audit, new code should use this
    // option explicitly to fix/tweak the alignment of the button label and
    // icon. Once all existing uses have migrated, can change the default.
    centerAlign?: boolean;
}

export const OverflowMenuOption: React.FC<OverflowMenuOptionProps> = ({
    onClick,
    color = "primary",
    startIcon,
    endIcon,
    centerAlign,
    children,
}) => {
    const menuContext = useContext(OverflowMenuContext);

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
                            marginBlockStart: centerAlign ? "6px" : 0,
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
