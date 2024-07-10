import { Divider } from "@mui/material";
import React from "react";

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
