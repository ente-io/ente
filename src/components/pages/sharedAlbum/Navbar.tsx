import { CenteredFlex, FluidContainer } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';
import NavbarBase from 'components/Navbar/base';
import UploadButton from 'components/Upload/UploadButton';
import React from 'react';
import constants from 'utils/strings/constants';
import GoToEnte from './GoToEnte';

export default function SharedAlbumNavbar({ showUploadButton, openUploader }) {
    return (
        <NavbarBase>
            <FluidContainer>
                <CenteredFlex>
                    <EnteLogo />
                </CenteredFlex>
            </FluidContainer>
            {showUploadButton ? (
                <UploadButton
                    openUploader={openUploader}
                    text={constants.ADD_PHOTOS}
                />
            ) : (
                <GoToEnte />
            )}
        </NavbarBase>
    );
}
