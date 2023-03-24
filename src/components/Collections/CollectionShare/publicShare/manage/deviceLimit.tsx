import { ChevronRight } from '@mui/icons-material';
import { DialogContent } from '@mui/material';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import { t } from 'i18next';
import React, { useEffect, useState } from 'react';
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
    const changeDeviceLimitValue = (value: number) => () => {
        updateDeviceLimit(value);
        publicShareProp.deviceLimit = value;
        setChangeDeviceLimitView(false);
    };

    useEffect(() => {
        if (changeDeviceLimitView) {
            setChangeDeviceLimitView(true);
        } else setChangeDeviceLimitView(false);
    }, [changeDeviceLimitView]);

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
                    <tbody>
                        {getDeviceLimitOptions().map((item) => (
                            <tr key={item.label}>
                                <td>
                                    <EnteMenuItem
                                        onClick={changeDeviceLimitValue(
                                            item.value
                                        )}>
                                        {item.label}
                                    </EnteMenuItem>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </DialogContent>
            </EnteDrawer>
        </>
    );
}
