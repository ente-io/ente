import { FluidContainer } from 'components/Container';
import NavbarBase from 'components/Navbar/base';
import { LogoImage } from 'pages/_app';
import React from 'react';
import GoToEnte from './GoToEnte';

export default function SharedAlbumNavbar() {
    return (
        <NavbarBase>
            <FluidContainer>
                <LogoImage
                    style={{ height: '24px', padding: '3px' }}
                    alt="logo"
                    src="/icon.svg"
                />
            </FluidContainer>
            <GoToEnte />
        </NavbarBase>
    );
}
