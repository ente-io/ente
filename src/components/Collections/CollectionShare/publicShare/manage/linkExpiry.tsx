import { Box, Typography } from '@mui/material';
import React from 'react';
import Select from 'react-select';
import { linkExpiryStyle } from 'styles/linkExpiry';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import { shareExpiryOptions } from 'utils/collection';
import constants from 'utils/strings/constants';
import { formatDateTime } from 'utils/time/format';
import { OptionWithDivider } from './selectComponents/OptionWithDivider';

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
            validTill: optionFn(),
        });
    };
    return (
        <Box>
            <Typography mb={0.5}>{constants.LINK_EXPIRY}</Typography>
            <Select
                menuPosition="fixed"
                options={shareExpiryOptions}
                isSearchable={false}
                value={null}
                components={{
                    Option: OptionWithDivider,
                }}
                placeholder={
                    publicShareProp?.validTill
                        ? formatDateTime(publicShareProp?.validTill / 1000)
                        : 'never'
                }
                onChange={(e) => {
                    updateDeviceExpiry(e.value);
                }}
                styles={linkExpiryStyle}
            />
        </Box>
    );
}
