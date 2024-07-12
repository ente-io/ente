import { VerticallyCenteredFlex } from "@ente/shared/components/Container";
import { Divider, styled, Typography } from "@mui/material";
import React from "react";

interface MenuSectionTitleProps {
    title: string;
    icon?: JSX.Element;
}

export const MenuSectionTitle: React.FC<MenuSectionTitleProps> = ({
    title,
    icon,
}) => {
    return (
        <VerticallyCenteredFlex
            px="8px"
            py={"6px"}
            gap={"8px"}
            sx={{
                "& > svg": {
                    fontSize: "17px",
                    color: (theme) => theme.colors.stroke.muted,
                },
            }}
        >
            {icon && icon}
            <Typography variant="small" color="text.muted">
                {title}
            </Typography>
        </VerticallyCenteredFlex>
    );
};

interface MenuItemDividerProps {
    hasIcon?: boolean;
}

export const MenuItemDivider: React.FC<MenuItemDividerProps> = ({
    hasIcon,
}) => {
    return (
        <Divider
            sx={{
                "&&&": {
                    my: 0,
                    ml: hasIcon ? "48px" : "16px",
                },
            }}
        />
    );
};

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
    background-color: ${theme.colors.fill.faint};
    border-radius: 8px;
`,
);
