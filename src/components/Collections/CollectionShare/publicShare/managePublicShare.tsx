import { Stack, Typography } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/menuItem';
import EnteMenuItemDivider from 'components/Menu/menuItemDivider';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';
import { Collection, PublicURL } from 'types/collection';
import ManagePublicShareOptions from './manage';
import PublicIcon from '@mui/icons-material/Public';
import ContentCopyIcon from '@mui/icons-material/ContentCopyOutlined';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { SetPublicShareProp } from 'types/publicCollection';
import LinkIcon from '@mui/icons-material/Link';
import { useState } from 'react';
import { t } from 'i18next';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    onRootClose: () => void;
    publicShareUrl: string;
    copyToClipboardHelper: () => void;
}
export default function ManagePublicShare({
    publicShareProp,
    setPublicShareProp,
    collection,
    onRootClose,
    publicShareUrl,
    copyToClipboardHelper,
}: Iprops) {
    const [manageShareView, setManageShareView] = useState(false);
    const closeManageShare = () => setManageShareView(false);
    const openManageShare = () => setManageShareView(true);
    return (
        <>
            <Stack>
                <Typography color="text.secondary" variant="body2" padding={1}>
                    <PublicIcon style={{ fontSize: 17, marginRight: 8 }} />
                    {t('PUBLIC_LINK_ENABLED')}
                </Typography>
                <EnteMenuItemGroup>
                    <EnteMenuItem
                        startIcon={<ContentCopyIcon />}
                        onClick={copyToClipboardHelper}>
                        {t('COPY_LINK')}
                    </EnteMenuItem>
                    <EnteMenuItemDivider />
                    <EnteMenuItem
                        startIcon={<LinkIcon />}
                        endIcon={<ChevronRightIcon />}
                        onClick={openManageShare}>
                        {t('MANAGE_LINK')}
                    </EnteMenuItem>
                </EnteMenuItemGroup>
            </Stack>
            <ManagePublicShareOptions
                open={manageShareView}
                onClose={closeManageShare}
                onRootClose={onRootClose}
                publicShareProp={publicShareProp}
                collection={collection}
                setPublicShareProp={setPublicShareProp}
                publicShareUrl={publicShareUrl}
            />
        </>
    );
}
