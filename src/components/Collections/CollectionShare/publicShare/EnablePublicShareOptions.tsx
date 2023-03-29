import { Stack, Typography } from '@mui/material';
import { GalleryContext } from 'pages/gallery';
import React, { useContext, useState } from 'react';
import { t } from 'i18next';
import {
    createShareableURL,
    updateShareableURL,
} from 'services/collectionService';
import { Collection, PublicURL } from 'types/collection';
import { handleSharingErrors } from 'utils/error/ui';
import { EnteMenuItem } from 'components/Menu/menuItem';
import PublicIcon from '@mui/icons-material/Public';
interface Iprops {
    collection: Collection;
    setPublicShareProp: (value: PublicURL) => void;
    setCopyLinkModalView: (value: boolean) => void;
}
import LinkIcon from '@mui/icons-material/Link';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import EnteMenuItemDivider from 'components/Menu/menuItemDivider';

export default function EnablePublicShareOptions({
    collection,
    setPublicShareProp,
    setCopyLinkModalView,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);
    const [sharableLinkError, setSharableLinkError] = useState(null);

    const createSharableURLHelper = async () => {
        try {
            setSharableLinkError(null);
            galleryContext.setBlockingLoad(true);
            const publicURL = await createShareableURL(collection);
            setPublicShareProp(publicURL);
            setCopyLinkModalView(true);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    const createCollectPhotoShareableURLHelper = async () => {
        try {
            setSharableLinkError(null);
            galleryContext.setBlockingLoad(true);
            const publicURL = await createShareableURL(collection);
            await updateShareableURL({
                collectionID: collection.id,
                enableCollect: true,
            });
            setPublicShareProp(publicURL);
            setCopyLinkModalView(true);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    return (
        <Stack>
            <MenuSectionTitle
                title={t('LINK_SHARE_TITLE')}
                icon={<PublicIcon />}
            />
            <EnteMenuItemGroup>
                <EnteMenuItem
                    startIcon={<LinkIcon />}
                    color="primary"
                    onClick={createSharableURLHelper}>
                    {t('CREATE_PUBLIC_SHARING')}
                </EnteMenuItem>
                <EnteMenuItemDivider hasIcon />
                <EnteMenuItem
                    startIcon={<LinkIcon />}
                    color="primary"
                    onClick={createCollectPhotoShareableURLHelper}>
                    {t('COLLECT_PHOTOS')}
                </EnteMenuItem>
            </EnteMenuItemGroup>
            {sharableLinkError && (
                <Typography
                    textAlign={'center'}
                    variant="body2"
                    sx={{
                        color: (theme) => theme.palette.danger.main,
                        mt: 0.5,
                    }}>
                    {sharableLinkError}
                </Typography>
            )}
        </Stack>
    );
}
