import { VerticallyCenteredFlex } from "@ente/shared/components/Container";
import { Typography } from "@mui/material";
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
