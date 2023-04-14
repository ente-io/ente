import { CenteredFlex, HorizontalFlex } from 'components/Container';
import NavbarBase from 'components/Navbar/base';
import React from 'react';
import { t } from 'i18next';
import { logoutUser } from 'services/userService';
import { EnteLogo } from 'components/EnteLogo';
import OverflowMenu from 'components/OverflowMenu/menu';
import { OverflowMenuOption } from 'components/OverflowMenu/option';
import MoreHoriz from '@mui/icons-material/MoreHoriz';
import LogoutOutlined from '@mui/icons-material/LogoutOutlined';

export default function AuthNavbar() {
    return (
        <NavbarBase>
            <CenteredFlex position={'absolute'}>
                <EnteLogo />
            </CenteredFlex>
            <HorizontalFlex width={'100%'} justifyContent={'flex-end'}>
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
