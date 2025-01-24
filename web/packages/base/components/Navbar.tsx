import { EnteLogo } from "@/base/components/EnteLogo";
import { CenteredFlex, FlexWrapper } from "@ente/shared/components/Container";
import { styled } from "@mui/material";
import React from "react";

/**
 * The "bar" at the top of the screen.
 *
 * Usually this area contains the App's main navigation bar ({@link AppNavbar}),
 * but depending on the context it can also show the {@link SelectionBar}.
 * */
export const NavbarBase = styled(FlexWrapper)(
    ({ theme }) => `
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 10;
    border-bottom: 1px solid ${theme.vars.palette.divider};
    background-color: ${theme.vars.palette.background.default};
    margin-bottom: 16px;
    padding: 0 24px;
    @media (max-width: 720px) {
        padding: 0 4px;
    }
`,
);

// TODO: Prune
export const AppNavbar: React.FC = () => {
    return (
        <NavbarBase>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
};

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

export const SelectionBar = styled(NavbarBase)`
    position: fixed;
    z-index: 12;
`;
