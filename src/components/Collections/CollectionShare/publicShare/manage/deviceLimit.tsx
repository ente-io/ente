import { ChevronRight } from '@mui/icons-material';
import { DialogContent } from '@mui/material';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import React, { useEffect, useState } from 'react';
import { Collection, PublicURL, UpdatePublicURL } from 'types/collection';
import { getDeviceLimitOptions } from 'utils/collection';
import constants from 'utils/strings/constants';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManageDeviceLimit({
    collection,
    updatePublicShareURLHelper,
}: Iprops) {
    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            deviceLimit: newLimit,
        });
    };
    const [shareDeviceLimitModalView, setDeviceLimitModalView] =
        useState(false);
    const [shareDeviceLimitValue, setDeviceLimitValue] = useState(0);
    useEffect(() => {
        if (shareDeviceLimitModalView) {
            setDeviceLimitModalView(true);
        } else setDeviceLimitModalView(false);
    }, [shareDeviceLimitModalView]);
    const closeShareExpiryOptionsModalView = () =>
        setDeviceLimitModalView(false);
    const openShareExpiryOptionsModalView = () => setDeviceLimitModalView(true);
    const changeshareExpiryValue = (value: number) => () => {
        updateDeviceLimit(value);
        setDeviceLimitValue(value);
        setDeviceLimitModalView(false);
    };
    return (
        <>
            <EnteMenuItem
                onClick={openShareExpiryOptionsModalView}
                endIcon={<ChevronRight />}
                subText={String(shareDeviceLimitValue)}
                isTopOfList={true}>
                {constants.LINK_DEVICE_LIMIT}
            </EnteMenuItem>
            <EnteDrawer
                anchor="right"
                open={shareDeviceLimitModalView}
                onClose={closeShareExpiryOptionsModalView}>
                <DialogTitleWithCloseButton
                    onClose={closeShareExpiryOptionsModalView}>
                    {constants.LINK_EXPIRY}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    {/* <OptionWithDivider data={shareExpiryOptions} /> */}
                    <tbody>
                        {getDeviceLimitOptions().map((item) => (
                            <tr key={item.label}>
                                <td>
                                    <EnteMenuItem
                                        onClick={changeshareExpiryValue(
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
