import React, { useEffect, useState } from 'react';
import { Collection, PublicURL } from 'types/collection';
import { appendCollectionKeyToShareURL } from 'utils/collection';
import BeforeShare from './beforeShare';
import PublicShareManage from './manage';
import ContentCopyIcon from '@mui/icons-material/ContentCopyOutlined';
import PublicIcon from '@mui/icons-material/Public';

import {
    DialogActions,
    Button,
    Stack,
    Typography,
    DialogContent,
    Box,
} from '@mui/material';
import LinkIcon from '@mui/icons-material/Link';
import { EnteMenuItem } from 'components/Menu/menuItem';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import VerticallyCentered from 'components/Container';
import DialogBoxBase from 'components/DialogBox/base';
import { Check } from '@mui/icons-material';
import { t } from 'i18next';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';

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
                    <Stack>
                        <Typography
                            color="text.secondary"
                            variant="body2"
                            padding={1}>
                            <PublicIcon
                                style={{ fontSize: 17, marginRight: 8 }}
                            />
                            {t('PUBLIC_LINK_ENABLED')}
                        </Typography>
                        <EnteMenuItemGroup>
                            <EnteMenuItem
                                startIcon={<ContentCopyIcon />}
                                onClick={copyToClipboardHelper(publicShareUrl)}
                                isTopOfList={true}>
                                {t('COPY_LINK')}
                            </EnteMenuItem>
                            <EnteMenuItem
                                startIcon={<LinkIcon />}
                                endIcon={<ChevronRightIcon />}
                                onClick={openManageShare}
                                isBottomOfList={true}>
                                {t('MANAGE_LINK')}
                            </EnteMenuItem>
                        </EnteMenuItemGroup>
                    </Stack>
                    <PublicShareManage
                        open={manageShareModalView}
                        onClose={closeManageShare}
                        publicShareProp={publicShareProp}
                        collection={collection}
                        setPublicShareProp={setPublicShareProp}
                        publicShareUrl={publicShareUrl}
                    />
                    <DialogBoxBase
                        open={isFirstShareProp}
                        onClose={handleCancel}
                        disablePortal
                        BackdropProps={{ sx: { position: 'absolute' } }}
                        sx={{ position: 'absolute' }}
                        PaperProps={{
                            sx: { p: 1, justifyContent: 'flex-end' },
                        }}>
                        <DialogContent>
                            <VerticallyCentered>
                                <Typography fontWeight={'bold'}>
                                    {t('PUBLIC_LINK_CREATED')}
                                </Typography>
                                <Box pt={2}>
                                    <Check sx={{ fontSize: '48px' }} />
                                </Box>
                            </VerticallyCentered>
                        </DialogContent>
                        <DialogActions>
                            <Button
                                onClick={handleCancel}
                                color="secondary"
                                size={'large'}>
                                {t('DONE')}
                            </Button>
                            <Button
                                onClick={copyToClipboardHelper(publicShareUrl)}
                                size={'large'}
                                color="primary"
                                autoFocus>
                                {t('COPY_LINK')}
                            </Button>
                        </DialogActions>
                    </DialogBoxBase>
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
