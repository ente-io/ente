import React from "react";
import { CenteredFlex } from "../../components/Container";
import { EnteLogo } from "../EnteLogo";
import NavbarBase from "./base";

export const AppNavbar: React.FC = () => {
    return (
        <NavbarBase>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
};
