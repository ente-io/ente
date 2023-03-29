import { ChevronRight } from '@mui/icons-material';
import { DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import React, { useMemo, useState } from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import { shareExpiryOptions } from 'utils/collection';
import { t } from 'i18next';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';
import { formatDateTime } from 'utils/time/format';
import Titlebar from 'components/Titlebar';
import EnteMenuItemDivider from 'components/Menu/menuItemDivider';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

export function ManageLinkExpiry({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
    onRootClose,
}: Iprops) {
    const updateDeviceExpiry = async (optionFn) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            validTill: optionFn,
        });
    };

    const [shareExpiryOptionsModalView, setShareExpiryOptionsModalView] =
        useState(false);

    const shareExpireOption = useMemo(() => shareExpiryOptions(), []);

    const closeShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(false);

    const openShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(true);

    const changeShareExpiryValue = (value: number) => async () => {
        await updateDeviceExpiry(value);
        publicShareProp.validTill = value;
        setShareExpiryOptionsModalView(false);
    };

    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            onRootClose();
        } else {
            closeShareExpiryOptionsModalView();
        }
    };

    return (
        <>
            <EnteMenuItem
                onClick={openShareExpiryOptionsModalView}
                endIcon={<ChevronRight />}
                subText={
                    publicShareProp?.validTill
                        ? formatDateTime(publicShareProp?.validTill / 1000)
                        : t('LINK_EXPIRY_NEVER')
                }>
                {t('LINK_EXPIRY')}
            </EnteMenuItem>
            <EnteDrawer
                anchor="right"
                open={shareExpiryOptionsModalView}
                onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={closeShareExpiryOptionsModalView}
                        title={t('LINK_EXPIRY')}
                        onRootClose={onRootClose}
                    />
                    <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                        <EnteMenuItemGroup>
                            {shareExpireOption.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        key={item.value()}
                                        onClick={changeShareExpiryValue(
                                            item.value()
                                        )}>
                                        {item.label}
                                    </EnteMenuItem>
                                    {index !== shareExpireOption.length - 1 && (
                                        <EnteMenuItemDivider />
                                    )}
                                </>
                            ))}
                        </EnteMenuItemGroup>
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
