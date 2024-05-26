import React from "react";
import { CenteredFlex } from "../../components/Container";
import { EnteLogo } from "../EnteLogo";
import NavbarBase from "./base";

interface AppNavbarProps {
    isMobile: boolean;
}

export const AppNavbar: React.FC<AppNavbarProps> = ({ isMobile }) => {
    return (
        <NavbarBase isMobile={isMobile}>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
};
