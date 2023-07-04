import { Stack, Typography } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import { Collection, PublicURL } from 'types/collection';
import PublicIcon from '@mui/icons-material/Public';
// import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { SetPublicShareProp } from 'types/publicCollection';
import AddIcon from '@mui/icons-material/Add';
import { useState } from 'react';
import { t } from 'i18next';
import ManageAddViewerOptions from './ManageAddViewerOptions';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
    onRootClose: () => void;
    publicShareUrl: string;
}
export default function ManageAddViewer({
    publicShareProp,
    setPublicShareProp,
    collection,
    onRootClose,
    publicShareUrl,
}: Iprops) {
    const [manageAddViewer, setManageAddViewer] = useState(false);
    const closeManageAddViewer = () => setManageAddViewer(false);
    const openManageAddViewer = () => setManageAddViewer(true);
    return (
        <>
            <Stack>
                {collection.sharees.length === 0 && (
                    <Typography color="text.muted" variant="small" padding={1}>
                        <PublicIcon style={{ fontSize: 17, marginRight: 8 }} />
                        {t('Share with specific people')}
                    </Typography>
                )}

                <MenuItemGroup>
                    <EnteMenuItem
                        startIcon={<AddIcon />}
                        onClick={openManageAddViewer}
                        label={t('Add Viewers')}
                    />
                </MenuItemGroup>
            </Stack>
            <ManageAddViewerOptions
                open={manageAddViewer}
                onClose={closeManageAddViewer}
                onRootClose={onRootClose}
                publicShareProp={publicShareProp}
                collection={collection}
                setPublicShareProp={setPublicShareProp}
                publicShareUrl={publicShareUrl}
            />
        </>
    );
}
