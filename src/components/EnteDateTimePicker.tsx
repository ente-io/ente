import React from 'react';

import {
    MIN_EDITED_CREATION_TIME,
    MAX_EDITED_CREATION_TIME,
} from 'constants/file';
import { TextField } from '@mui/material';
import {
    LocalizationProvider,
    DesktopDateTimePicker,
} from '@mui/x-date-pickers';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';

interface Props {
    loading?: boolean;
    value: Date;
    label?: string;
    onChange: (date: Date) => void;
}

const EnteDateTimePicker = ({ loading, value, onChange }: Props) => (
    <>
        <LocalizationProvider dateAdapter={AdapterDateFns}>
            <DesktopDateTimePicker
                maxDateTime={MAX_EDITED_CREATION_TIME}
                minDateTime={MIN_EDITED_CREATION_TIME}
                disabled={loading}
                PopperProps={{ sx: { zIndex: '1502' } }}
                value={value}
                onChange={onChange}
                renderInput={(params) => <TextField {...params} />}
            />
        </LocalizationProvider>
    </>
);

export default EnteDateTimePicker;
