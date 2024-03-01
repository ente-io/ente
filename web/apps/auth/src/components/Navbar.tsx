import { logoutUser } from "@ente/accounts/services/user";
import { HorizontalFlex } from "@ente/shared/components/Container";
import { EnteLogo } from "@ente/shared/components/EnteLogo";
import NavbarBase from "@ente/shared/components/Navbar/base";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import LogoutOutlined from "@mui/icons-material/LogoutOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React from "react";

export default function AuthNavbar() {
    const { isMobile } = React.useContext(AppContext);
    return (
        <NavbarBase isMobile={isMobile}>
            <HorizontalFlex flex={1} justifyContent={"center"}>
                <EnteLogo />
            </HorizontalFlex>
            <HorizontalFlex position={"absolute"} right="24px">
                <OverflowMenu
                    ariaControls={"auth-options"}
                    triggerButtonIcon={<MoreHoriz />}
                >
                    <OverflowMenuOption
                        color="critical"
                        startIcon={<LogoutOutlined />}
                        onClick={logoutUser}
                    >
                        {t("LOGOUT")}
                    </OverflowMenuOption>
                </OverflowMenu>
            </HorizontalFlex>
        </NavbarBase>
    );
}
