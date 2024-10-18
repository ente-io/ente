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
export const NavbarBase = styled(FlexWrapper)`
    min-height: 64px;
    position: sticky;
    top: 0;
    left: 0;
    z-index: 10;
    border-bottom: 1px solid ${({ theme }) => theme.palette.divider};
    background-color: ${({ theme }) => theme.colors.background.base};
    margin-bottom: 16px;
    padding: 0 24px;
    @media (max-width: 720px) {
        padding: 0 4px;
    }
`;

export const AppNavbar: React.FC = () => {
    return (
        <NavbarBase>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
};

export const SelectionBar = styled(NavbarBase)`
    position: fixed;
    z-index: 12;
`;
