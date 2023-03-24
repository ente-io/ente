import { ChevronRight } from '@mui/icons-material';
import { DialogContent, Divider } from '@mui/material';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { EnteDrawer } from 'components/EnteDrawer';
import { EnteMenuItem } from 'components/Menu/menuItem';
import React, { useMemo, useState } from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import { shareExpiryOptions } from 'utils/collection';
import { t } from 'i18next';
import { EnteMenuItemGroup } from 'components/Menu/menuItemGroup';
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

    const closeShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(false);

    const openShareExpiryOptionsModalView = () =>
        setShareExpiryOptionsModalView(true);

    const changeShareExpiryValue = (value: number) => async () => {
        await updateDeviceExpiry(value);
        publicShareProp.validTill = value;
        setShareExpiryOptionsModalView(false);
    };

    const shareExpireOption = useMemo(() => shareExpiryOptions(), []);

    return (
        <>
            <EnteMenuItem
                onClick={openShareExpiryOptionsModalView}
                endIcon={<ChevronRight />}
                subText={
                    publicShareProp?.validTill
                        ? formatDateTime(publicShareProp?.validTill / 1000)
                        : 'never'
                }>
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
                                    <Divider sx={{ '&&&': { m: 0 } }} />
                                )}
                            </>
                        ))}
                    </EnteMenuItemGroup>
                </DialogContent>
            </EnteDrawer>
        </>
    );
}
