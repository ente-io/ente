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
import React, { createContext, useContext, useState } from "react";

const OverflowMenuContext = createContext({
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    close: () => {},
});

interface OverflowMenuProps {
    triggerButtonIcon: React.ReactNode;
    triggerButtonProps?: Partial<IconButtonProps>;
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

export const OverflowMenu: React.FC<OverflowMenuProps> = ({
    children,
    ariaControls,
    triggerButtonIcon,
    triggerButtonProps,
    menuPaperProps,
}) => {
    const [sortByEl, setSortByEl] = useState<MenuProps["anchorEl"] | null>(
        null,
    );
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
};

interface OverflowMenuOptionProps {
    onClick: () => void;
    color?: ButtonProps["color"];
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    keepOpenAfterClick?: boolean;
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
    keepOpenAfterClick,
    centerAlign,
    children,
}) => {
    const menuContext = useContext(OverflowMenuContext);

    const handleClick = () => {
        onClick();
        if (!keepOpenAfterClick) {
            menuContext.close();
        }
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
