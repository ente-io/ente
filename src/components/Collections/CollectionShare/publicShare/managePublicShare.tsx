import { Stack, Typography } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
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
                <Typography color="text.muted" variant="small" padding={1}>
                    <PublicIcon style={{ fontSize: 17, marginRight: 8 }} />
                    {t('PUBLIC_LINK_ENABLED')}
                </Typography>
                <MenuItemGroup>
                    <EnteMenuItem
                        startIcon={<ContentCopyIcon />}
                        onClick={copyToClipboardHelper}>
                        <Typography fontWeight={'bold'}>
                            {t('COPY_LINK')}
                        </Typography>
                    </EnteMenuItem>
                    <MenuItemDivider hasIcon={true} />
                    <EnteMenuItem
                        startIcon={<LinkIcon />}
                        endIcon={<ChevronRightIcon />}
                        onClick={openManageShare}>
                        <Typography fontWeight={'bold'}>
                            {t('MANAGE_LINK')}
                        </Typography>
                    </EnteMenuItem>
                </MenuItemGroup>
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
