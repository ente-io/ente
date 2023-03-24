import { ChevronRight } from '@mui/icons-material';
import { DialogContent, Divider } from '@mui/material';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';
import { t } from 'i18next';
import React, { useMemo, useState } from 'react';
import { Collection, PublicURL, UpdatePublicURL } from 'types/collection';
import { getDeviceLimitOptions } from 'utils/collection';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManageDeviceLimit({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
}: Iprops) {
    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            deviceLimit: newLimit,
        });
    };
    const [changeDeviceLimitView, setChangeDeviceLimitView] = useState(false);
    const closeShareExpiryOptionsModalView = () =>
        setChangeDeviceLimitView(false);
    const openShareExpiryOptionsModalView = () =>
        setChangeDeviceLimitView(true);
    const changeDeviceLimitValue = (value: number) => async () => {
        await updateDeviceLimit(value);
        publicShareProp.deviceLimit = value;
        setChangeDeviceLimitView(false);
    };
    const deviceLimitOptions = useMemo(() => getDeviceLimitOptions(), []);

    return (
        <>
            <EnteMenuItem
                onClick={openShareExpiryOptionsModalView}
                endIcon={<ChevronRight />}
                subText={String(publicShareProp.deviceLimit)}>
                {t('LINK_DEVICE_LIMIT')}
            </EnteMenuItem>
            <EnteDrawer
                anchor="right"
                open={changeDeviceLimitView}
                onClose={closeShareExpiryOptionsModalView}>
                <DialogTitleWithCloseButton
                    onClose={closeShareExpiryOptionsModalView}>
                    {t('LINK_EXPIRY')}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    <EnteMenuItemGroup>
                        {deviceLimitOptions.map((item) => (
                            <>
                                <EnteMenuItem
                                    key={item.label}
                                    onClick={changeDeviceLimitValue(
                                        item.value
                                    )}>
                                    {item.label}
                                </EnteMenuItem>
                                <Divider sx={{ '&&&': { m: 0 } }} />
                            </>
                        ))}
                    </EnteMenuItemGroup>
                </DialogContent>
            </EnteDrawer>
        </>
    );
}
