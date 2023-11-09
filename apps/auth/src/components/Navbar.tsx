import { HorizontalFlex } from '@ente/shared/components/Container';
import NavbarBase from '@ente/shared/components/Navbar/base';
import React from 'react';
import { t } from 'i18next';
import { logoutUser } from '@ente/accounts/services/user';
import { EnteLogo } from '@ente/shared/components/EnteLogo';
import OverflowMenu from '@ente/shared/components/OverflowMenu/menu';
import { OverflowMenuOption } from '@ente/shared/components/OverflowMenu/option';
import MoreHoriz from '@mui/icons-material/MoreHoriz';
import LogoutOutlined from '@mui/icons-material/LogoutOutlined';
import { AppContext } from 'pages/_app';

export default function AuthNavbar() {
    const { isMobile } = React.useContext(AppContext);
    return (
        <NavbarBase isMobile={isMobile}>
            <HorizontalFlex flex={1} justifyContent={'center'}>
                <EnteLogo />
            </HorizontalFlex>
            <HorizontalFlex position={'absolute'} right="24px">
                <OverflowMenu
                    ariaControls={'auth-options'}
                    triggerButtonIcon={<MoreHoriz />}>
                    <OverflowMenuOption
                        color="critical"
                        startIcon={<LogoutOutlined />}
                        onClick={logoutUser}>
                        {t('LOGOUT')}
                    </OverflowMenuOption>
                </OverflowMenu>
            </HorizontalFlex>
        </NavbarBase>
    );
}
