import { ChevronRight } from '@mui/icons-material';
import { DialogContent } from '@mui/material';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import React, { useEffect, useState } from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import { shareExpiryOptions } from 'utils/collection';
import { t } from 'i18next';

import { formatDateTime } from 'utils/time/format';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManageLinkExpiry({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
}: Iprops) {
    const updateDeviceExpiry = async (optionFn) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            validTill: optionFn,
        });
    };
    const [shareExpiryOptionsModalView, setShareExpiryOptionsModalView] =
        useState(false);
    const [shareExpiryValue, setShareExpiryValue] = useState(0);
    const [labelText, setLabelText] = useState(
        publicShareProp?.validTill
            ? formatDateTime(publicShareProp?.validTill / 1000)
            : 'never'
    );
    useEffect(() => {
        if (shareExpiryOptionsModalView) {
            setShareExpiryOptionsModalView(true);
        } else setShareExpiryOptionsModalView(false);
    }, [shareExpiryOptionsModalView]);
    const closeShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(false);
    const openShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(true);
    const changeshareExpiryValue = (value: number) => () => {
        updateDeviceExpiry(value);
        setLabelText(
            publicShareProp?.validTill
                ? formatDateTime(publicShareProp?.validTill / 1000)
                : 'never'
        );
        setShareExpiryValue(value);
        shareExpiryValue;
        setShareExpiryOptionsModalView(false);
    };
    return (
        <>
            <EnteMenuItem
                onClick={openShareExpiryOptionsModalView}
                endIcon={<ChevronRight />}
                subText={labelText}>
                {t('LINK_EXPIRY')}
            </EnteMenuItem>
            <EnteDrawer
                anchor="right"
                open={shareExpiryOptionsModalView}
                onClose={closeShareExpiryOptionsModalView}>
                <DialogTitleWithCloseButton
                    onClose={closeShareExpiryOptionsModalView}>
                    {t('LINK_EXPIRY')}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    {/* <OptionWithDivider data={shareExpiryOptions} /> */}
                    <tbody>
                        {shareExpiryOptions().map((item) => (
                            <tr key={item.label}>
                                <td>
                                    <EnteMenuItem
                                        onClick={changeshareExpiryValue(
                                            item.value()
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
