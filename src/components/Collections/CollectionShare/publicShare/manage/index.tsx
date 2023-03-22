import { ManageLinkPassword } from './linkPassword';
import { ManageDeviceLimit } from './deviceLimit';
import { ManageLinkExpiry } from './linkExpiry';
import { DialogContent, Stack, Typography } from '@mui/material';
import { GalleryContext } from 'pages/gallery';
import React, { useContext, useState } from 'react';
import {
    deleteShareableURL,
    updateShareableURL,
} from 'services/collectionService';
import { Collection, PublicURL, UpdatePublicURL } from 'types/collection';
import constants from 'utils/strings/constants';
import { ManageDownloadAccess } from './downloadAccess';
import { handleSharingErrors } from 'utils/error/ui';
import { SetPublicShareProp } from 'types/publicCollection';
import { ManagePublicCollect } from './publicCollect';
import { EnteDrawer } from 'components/EnteDrawer';
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from 'components/DialogBox/TitleWithCloseButton';
import RemoveCircleOutline from '@mui/icons-material/RemoveCircleOutline';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import { EnteMenuItem } from 'components/Menu/menuItem';
interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    open: boolean;
    onClose: () => void;
    publicShareUrl: string;
}

export default function PublicShareManage({
    publicShareProp,
    collection,
    setPublicShareProp,
    open,
    onClose,
    publicShareUrl,
}: Iprops) {
    const handleClose = dialogCloseHandler({
        onClose: onClose,
    });
    const galleryContext = useContext(GalleryContext);

    const [sharableLinkError, setSharableLinkError] = useState(null);

    const updatePublicShareURLHelper = async (req: UpdatePublicURL) => {
        try {
            galleryContext.setBlockingLoad(true);
            const response = await updateShareableURL(req);
            setPublicShareProp(response);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };
    const disablePublicSharing = async () => {
        //appContext.startLoading();
        await deleteShareableURL(collection);
        setPublicShareProp(null);
        // await galleryContext.syncWithRemote(false, true);
    };
    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
    };
    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleClose}>
                <DialogTitleWithCloseButton onClose={handleClose}>
                    {constants.SHARE_COLLECTION}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    <Stack spacing={3}>
                        <ManagePublicCollect
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <ManageLinkExpiry
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <Stack>
                            <ManageDeviceLimit
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                            />
                            <ManageDownloadAccess
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                            />
                            <ManageLinkPassword
                                collection={collection}
                                publicShareProp={publicShareProp}
                                updatePublicShareURLHelper={
                                    updatePublicShareURLHelper
                                }
                            />
                        </Stack>
                        <EnteMenuItem
                            startIcon={<ContentCopyIcon />}
                            onClick={copyToClipboardHelper(publicShareUrl)}
                            isTopOfList={true}
                            isBottomOfList={true}>
                            {constants.COPY_LINK}
                        </EnteMenuItem>
                        <EnteMenuItem
                            color="danger"
                            startIcon={<RemoveCircleOutline />}
                            onClick={disablePublicSharing}
                            isTopOfList={true}
                            isBottomOfList={true}>
                            {constants.REMOVE_LINK}
                        </EnteMenuItem>
                    </Stack>
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
                </DialogContent>
            </EnteDrawer>
        </>
    );
}
