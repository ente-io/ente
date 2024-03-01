import { CenteredFlex } from "../../components/Container";
import { EnteLogo } from "../EnteLogo";
import NavbarBase from "./base";

export default function AppNavbar({ isMobile }) {
    return (
        <NavbarBase isMobile={isMobile}>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
}
