import { FluidContainer } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';
import NavbarBase from 'components/Navbar/base';
import React from 'react';
import GoToEnte from './GoToEnte';

export default function SharedAlbumNavbar() {
    return (
        <NavbarBase>
            <FluidContainer>
                <EnteLogo />
            </FluidContainer>
            <GoToEnte />
        </NavbarBase>
    );
}
