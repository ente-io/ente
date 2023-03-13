import { EnteLinkLogo } from 'components/Navbar/EnteLinkLogo';
import { FluidContainer } from 'components/Container';
import NavbarBase from 'components/Navbar/base';
import UploadButton from 'components/Upload/UploadButton';
import React from 'react';
import GoToEnte from './GoToEnte';
import { useTranslation } from 'react-i18next';

export default function SharedAlbumNavbar({ showUploadButton, openUploader }) {
    const { t } = useTranslation();

    return (
        <NavbarBase>
            <FluidContainer>
                <EnteLinkLogo />
            </FluidContainer>
            {showUploadButton ? (
                <UploadButton
                    openUploader={openUploader}
                    text={t('ADD_PHOTOS')}
                />
            ) : (
                <GoToEnte />
            )}
        </NavbarBase>
    );
}
