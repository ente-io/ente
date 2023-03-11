import React, { useEffect, useState } from 'react';
import { Collection, PublicURL } from 'types/collection';
import { appendCollectionKeyToShareURL } from 'utils/collection';
import BeforeShare from './beforeShare';
import PublicShareManage from './manage';
import ContentCopyIcon from '@mui/icons-material/ContentCopyOutlined';
import constants from 'utils/strings/constants';
import { Dialog, DialogTitle, DialogActions, Button } from '@mui/material';
import LinkIcon from '@mui/icons-material/Link';
import { EnteMenuItem } from 'components/Menu/menuItem';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';

export default function PublicShare({
    collection,
}: {
    collection: Collection;
}) {
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);
    const [isFirstShareProp, setIsFirstShareProp] = useState(false);
    const [manageShareModalView, setManageShareModalView] = useState(false);

    useEffect(() => {
        if (collection.publicURLs?.length) {
            setPublicShareProp(collection.publicURLs[0]);
        }
    }, [collection]);

    useEffect(() => {
        if (publicShareProp) {
            const url = appendCollectionKeyToShareURL(
                publicShareProp.url,
                collection.key
            );
            setPublicShareUrl(url);
        } else {
            setPublicShareUrl(null);
        }
    }, [publicShareProp]);

    useEffect(() => {
        if (isFirstShareProp) {
            setIsFirstShareProp(true);
            setManageShareModalView(false);
        } else setIsFirstShareProp(false);
    }, [isFirstShareProp]);

    useEffect(() => {
        if (manageShareModalView) {
            setManageShareModalView(true);
        } else setManageShareModalView(false);
    }, [manageShareModalView]);

    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
    };
    const handleCancel = () => {
        setIsFirstShareProp(false);
    };

    const closeManageShare = () => setManageShareModalView(false);
    const openManageShare = () => setManageShareModalView(true);
    return (
        <>
            {publicShareProp ? (
                <>
                    <EnteMenuItem
                        startIcon={<ContentCopyIcon />}
                        onClick={copyToClipboardHelper(publicShareUrl)}>
                        {constants.COPY_LINK}
                    </EnteMenuItem>

                    <EnteMenuItem
                        startIcon={<LinkIcon />}
                        endIcon={<ChevronRightIcon />}
                        onClick={openManageShare}>
                        {constants.MANAGE_LINK}
                    </EnteMenuItem>
                    <PublicShareManage
                        open={manageShareModalView}
                        onClose={closeManageShare}
                        publicShareProp={publicShareProp}
                        collection={collection}
                        setPublicShareProp={setPublicShareProp}
                        publicShareUrl={publicShareUrl}
                    />
                    <Dialog
                        open={isFirstShareProp}
                        onClose={handleCancel}
                        disablePortal
                        BackdropProps={{ sx: { position: 'absolute' } }}
                        sx={{ position: 'absolute' }}
                        PaperProps={{
                            sx: { p: 1, justifyContent: 'flex-end' },
                        }}>
                        <DialogTitle>
                            {constants.PUBLIC_LINK_CREATED}
                        </DialogTitle>
                        <DialogActions>
                            <Button onClick={handleCancel} color="primary">
                                Cancel
                            </Button>
                            <Button
                                onClick={copyToClipboardHelper(publicShareUrl)}
                                color="primary"
                                autoFocus>
                                {constants.COPY_LINK}
                            </Button>
                        </DialogActions>
                    </Dialog>
                </>
            ) : (
                <BeforeShare
                    publicShareProp={publicShareProp}
                    setPublicShareProp={setPublicShareProp}
                    collection={collection}
                    publicShareActive={!!publicShareProp}
                    setIsFirstShareProp={setIsFirstShareProp}
                />
            )}
        </>
    );
}
