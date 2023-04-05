import { EnteLinkLogo } from 'components/Navbar/EnteLinkLogo';
import { FluidContainer } from 'components/Container';
import NavbarBase from 'components/Navbar/base';
import UploadButton from 'components/Upload/UploadButton';
import React from 'react';
import GoToEnte from './GoToEnte';
import { t } from 'i18next';
import AddPhotoAlternateOutlined from '@mui/icons-material/AddPhotoAlternateOutlined';

export default function SharedAlbumNavbar({ showUploadButton, openUploader }) {
    return (
        <NavbarBase>
            <FluidContainer>
                <EnteLinkLogo />
            </FluidContainer>
            {showUploadButton ? (
                <UploadButton
                    openUploader={openUploader}
                    icon={<AddPhotoAlternateOutlined />}
                    text={t('ADD_PHOTOS')}
                />
            ) : (
                <GoToEnte />
            )}
        </NavbarBase>
    );
}
