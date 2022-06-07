import { Box } from '@mui/material';
import { DropdownStyle } from 'components/Collections/CollectionShare/styles';
import React from 'react';
import Select from 'react-select';
import { shareExpiryOptions } from 'utils/collection';
import constants from 'utils/strings/constants';
import { dateStringWithMMH } from 'utils/time';

const linkExpiryStyle = {
    ...DropdownStyle,
    placeholder: (style) => ({
        ...style,
        color: '#d1d1d1',
        width: '100%',
        textAlign: 'center',
    }),
};

export function ManageLinkExpiry({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
}) {
    const updateDeviceExpiry = async (optionFn) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            validTill: optionFn(),
        });
    };
    return (
        <Box>
            {constants.LINK_EXPIRY}
            <Select
                menuPosition="fixed"
                options={shareExpiryOptions}
                isSearchable={false}
                value={null}
                placeholder={
                    publicShareProp?.validTill
                        ? dateStringWithMMH(publicShareProp?.validTill)
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
