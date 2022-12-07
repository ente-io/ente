import { Link } from '@mui/material';
import Box from '@mui/material/Box';
import { FluidContainer } from 'components/Container';
import Ente from 'components/icons/ente';
import NavbarBase from 'components/Navbar/base';
import UploadButton from 'components/Upload/UploadButton';
import { ENTE_WEBSITE_LINK } from 'constants/urls';
import React from 'react';
import constants from 'utils/strings/constants';
import GoToEnte from './GoToEnte';

export default function SharedAlbumNavbar({ showUploadButton, openUploader }) {
    return (
        <NavbarBase>
            <FluidContainer>
                <Link href={ENTE_WEBSITE_LINK}>
                    <Box
                        sx={(theme) => ({
                            ':hover': {
                                cursor: 'pointer',
                                svg: {
                                    fill: theme.palette.text.secondary,
                                },
                            },
                        })}>
                        <Ente />
                    </Box>
                </Link>
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
