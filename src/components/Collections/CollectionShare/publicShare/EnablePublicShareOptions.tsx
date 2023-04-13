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
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import PublicIcon from '@mui/icons-material/Public';
interface Iprops {
    collection: Collection;
    setPublicShareProp: (value: PublicURL) => void;
    setCopyLinkModalView: (value: boolean) => void;
}
import LinkIcon from '@mui/icons-material/Link';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import MenuItemDivider from 'components/Menu/MenuItemDivider';

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
            <MenuItemGroup>
                <EnteMenuItem
                    startIcon={<LinkIcon />}
                    color="primary"
                    onClick={createSharableURLHelper}>
                    <Typography fontWeight={'bold'}>
                        {t('CREATE_PUBLIC_SHARING')}
                    </Typography>
                </EnteMenuItem>
                <MenuItemDivider hasIcon />
                <EnteMenuItem
                    startIcon={<LinkIcon />}
                    color="primary"
                    onClick={createCollectPhotoShareableURLHelper}>
                    <Typography fontWeight={'bold'}>
                        {t('COLLECT_PHOTOS')}
                    </Typography>
                </EnteMenuItem>
            </MenuItemGroup>
            {sharableLinkError && (
                <Typography
                    textAlign={'center'}
                    variant="small"
                    sx={{
                        color: (theme) => theme.colors.caution.A500,
                        mt: 0.5,
                    }}>
                    {sharableLinkError}
                </Typography>
            )}
        </Stack>
    );
}
