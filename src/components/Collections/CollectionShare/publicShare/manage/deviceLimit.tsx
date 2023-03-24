import { ChevronRight } from '@mui/icons-material';
import { DialogProps, Divider, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';
import Titlebar from 'components/Titlebar';
import { t } from 'i18next';
import React, { useMemo, useState } from 'react';
import { Collection, PublicURL, UpdatePublicURL } from 'types/collection';
import { getDeviceLimitOptions } from 'utils/collection';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
    onRootClose: () => void;
}

export function ManageDeviceLimit({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    onRootClose,
}: Iprops) {
    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            deviceLimit: newLimit,
        });
    };
    const [changeDeviceLimitView, setChangeDeviceLimitView] = useState(false);
    const deviceLimitOptions = useMemo(() => getDeviceLimitOptions(), []);

    const closeDeviceLimitChangeModalView = () =>
        setChangeDeviceLimitView(false);
    const openDeviceLimitChangeModalView = () => setChangeDeviceLimitView(true);

    const changeDeviceLimitValue = (value: number) => async () => {
        await updateDeviceLimit(value);
        publicShareProp.deviceLimit = value;
        setChangeDeviceLimitView(false);
    };

    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            onRootClose();
        } else {
            closeDeviceLimitChangeModalView();
        }
    };

    return (
        <>
            <EnteMenuItem
                onClick={openDeviceLimitChangeModalView}
                endIcon={<ChevronRight />}
                subText={String(publicShareProp.deviceLimit)}>
                {t('LINK_DEVICE_LIMIT')}
            </EnteMenuItem>

            <EnteDrawer
                anchor="right"
                open={changeDeviceLimitView}
                onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={closeDeviceLimitChangeModalView}
                        title={t('LINK_DEVICE_LIMIT')}
                        onRootClose={onRootClose}
                    />
                    <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                        <EnteMenuItemGroup>
                            {deviceLimitOptions.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        key={item.label}
                                        onClick={changeDeviceLimitValue(
                                            item.value
                                        )}>
                                        {item.label}
                                    </EnteMenuItem>
                                    {index !==
                                        deviceLimitOptions.length - 1 && (
                                        <Divider sx={{ '&&&': { m: 0 } }} />
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
