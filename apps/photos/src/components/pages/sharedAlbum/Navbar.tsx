import { EnteLinkLogo } from '@ente/shared/components/Navbar/EnteLinkLogo';
import { FluidContainer } from '@ente/shared/components/Container';
import NavbarBase from '@ente/shared/components/Navbar/base';
import UploadButton from 'components/Upload/UploadButton';
import React, { useContext } from 'react';
import GoToEnte from './GoToEnte';
import { t } from 'i18next';
import AddPhotoAlternateOutlined from '@mui/icons-material/AddPhotoAlternateOutlined';
import { AppContext } from 'pages/_app';

export default function SharedAlbumNavbar({ showUploadButton, openUploader }) {
    const { isMobile } = useContext(AppContext);
    return (
        <NavbarBase isMobile={isMobile}>
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
