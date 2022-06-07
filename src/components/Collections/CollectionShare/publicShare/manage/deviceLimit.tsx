import { Box } from '@mui/material';
import React from 'react';
import Select from 'react-select';
import { getDeviceLimitOptions } from 'utils/collection';
import constants from 'utils/strings/constants';
import { DropdownStyle } from '../../styles';
export function ManageDeviceLimit({
    publicShareProp,
    collection,
    updatePublicShareURLHelper,
}) {
    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: collection.id,
            deviceLimit: newLimit,
        });
    };

    return (
        <Box>
            {constants.LINK_DEVICE_LIMIT}
            <Select
                menuPosition="fixed"
                options={getDeviceLimitOptions()}
                isSearchable={false}
                value={{
                    label: publicShareProp?.deviceLimit.toString(),
                    value: publicShareProp?.deviceLimit,
                }}
                onChange={(e) => updateDeviceLimit(e.value)}
                styles={DropdownStyle}
            />
        </Box>
    );
}
