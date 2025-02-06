import { EnteLogo } from "@/base/components/EnteLogo";
import { styled } from "@mui/material";
import React from "react";

export const NavbarBaseNormalFlow = styled("div")(
    ({ theme }) => `
    flex: 0 0 64px;
    display: flex;
    justify-content: center;
    align-items: center;
    border-bottom: 1px solid ${theme.vars.palette.divider};
`,
);

/**
 * A variant of AppNavbar that places itself normally in the document flow
 * instead of using a fixed positioning.
 */
export const AppNavbarNormalFlow: React.FC = () => (
    <NavbarBaseNormalFlow>
        <EnteLogo />
    </NavbarBaseNormalFlow>
);
