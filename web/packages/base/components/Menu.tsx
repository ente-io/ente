import { Divider, Stack, styled, Typography } from "@mui/material";
import React from "react";

interface MenuSectionTitleProps {
    /**
     * The title for the menu section.
     */
    title: string;
    /**
     * An optional leading SvgIcon.
     */
    icon?: React.ReactNode;
}

export const MenuSectionTitle: React.FC<MenuSectionTitleProps> = ({
    title,
    icon,
}) => (
    <Stack
        direction="row"
        sx={{
            px: "8px",
            py: "6px",
            gap: "8px",
            "& > svg": {
                fontSize: "17px",
                color: "stroke.muted",
            },
        }}
    >
        {icon && icon}
        <Typography variant="small" sx={{ color: "text.muted" }}>
            {title}
        </Typography>
    </Stack>
);

interface MenuItemDividerProps {
    /**
     * If true, then the menu divider leaves the leading edge hanging which
     * visually looks better when used to separate menu items which have leading
     * icons.
     */
    hasIcon?: boolean;
}

export const MenuItemDivider: React.FC<MenuItemDividerProps> = ({
    hasIcon,
}) => (
    <Divider
        sx={[{ "&&&": { my: 0 } }, hasIcon ? { ml: "48px" } : { ml: "16px" }]}
    />
);

export const MenuItemGroup = styled("div")(
    ({ theme }) => `
    & > .MuiMenuItem-root{
        border-radius: 8px;
        background-color: transparent;
    }
    & > .MuiMenuItem-root:not(:last-of-type) {
        border-bottom-left-radius: 0;
        border-bottom-right-radius: 0;
    }
    & > .MuiMenuItem-root:not(:first-of-type) {
        border-top-left-radius: 0;
        border-top-right-radius: 0;
    }
    background-color: ${theme.vars.palette.fill.faint};
    border-radius: 8px;
`,
);
