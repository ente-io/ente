import { Box, Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import { ButtonVariant } from 'components/pages/gallery/LinkButton';
import { GalleryContext } from 'pages/gallery';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import {
    createShareableURL,
    deleteShareableURL,
} from 'services/collectionService';
import { appendCollectionKeyToShareURL } from 'utils/collection';
import { handleSharingErrors } from 'utils/error';
import constants from 'utils/strings/constants';
import PublicShareSwitch from './switch';
export default function PublicShareControl({
    publicShareUrl,
    sharableLinkError,
    collection,
    setPublicShareUrl,
    setSharableLinkError,
}) {
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const createSharableURLHelper = async () => {
        try {
            appContext.startLoading();
            const publicURL = await createShareableURL(collection);
            const sharableURL = await appendCollectionKeyToShareURL(
                publicURL.url,
                collection.key
            );
            setPublicShareUrl(sharableURL);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            appContext.finishLoading();
        }
    };

    const disablePublicSharing = async () => {
        try {
            appContext.startLoading();
            await deleteShareableURL(collection);
            setPublicShareUrl(null);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            appContext.finishLoading();
        }
    };

    const confirmDisablePublicSharing = () => {
        appContext.setDialogMessage({
            title: constants.DISABLE_PUBLIC_SHARING,
            content: constants.DISABLE_PUBLIC_SHARING_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                text: constants.DISABLE,
                action: disablePublicSharing,
                variant: ButtonVariant.danger,
            },
        });
    };

    const handleCollectionPublicSharing = () => {
        setSharableLinkError(null);

        if (publicShareUrl) {
            confirmDisablePublicSharing();
        } else {
            createSharableURLHelper();
        }
    };
    return (
        <Box mt={3}>
            <FlexWrapper>
                <FlexWrapper>{constants.PUBLIC_SHARING}</FlexWrapper>

                <PublicShareSwitch
                    color="accent"
                    sx={{
                        ml: 2,
                    }}
                    checked={!!publicShareUrl}
                    onChange={handleCollectionPublicSharing}
                />
            </FlexWrapper>
            {sharableLinkError && (
                <Typography
                    variant="body2"
                    sx={{
                        color: (theme) => theme.palette.danger.main,
                        mt: 0.5,
                    }}>
                    {sharableLinkError}
                </Typography>
            )}
        </Box>
    );
}
