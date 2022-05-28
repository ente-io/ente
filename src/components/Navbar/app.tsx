import { CenteredFlex } from 'components/Container';
import { LogoImage } from 'pages/_app';
import React from 'react';
import NavbarBase from './base';

export default function AppNavbar() {
    return (
        <NavbarBase>
            <CenteredFlex>
                <LogoImage
                    style={{ height: '24px', padding: '3px' }}
                    alt="logo"
                    src="/icon.svg"
                />
            </CenteredFlex>
        </NavbarBase>
    );
}
