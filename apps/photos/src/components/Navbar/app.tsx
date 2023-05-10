import { EnteLogo } from './../EnteLogo';
import { CenteredFlex } from 'components/Container';
import React from 'react';
import NavbarBase from './base';

export default function AppNavbar() {
    return (
        <NavbarBase>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
}
