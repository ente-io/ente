import React, { useState } from 'react';

import {
    MIN_EDITED_CREATION_TIME,
    MAX_EDITED_CREATION_TIME,
} from 'constants/file';
import { TextField } from '@mui/material';
import {
    LocalizationProvider,
    MobileDateTimePicker,
} from '@mui/x-date-pickers';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';

interface Props {
    loading?: boolean;
    value: Date;
    label?: string;
    onChange: (date: Date) => void;
}

const EnteDateTimePicker = ({ loading, value, onChange }: Props) => {
    const [open, setOpen] = useState(true);

    const handleChange = (newDate: Date) => {
        if (!isNaN(newDate?.getTime())) {
            onChange(newDate);
        }
    };

    return (
        <LocalizationProvider dateAdapter={AdapterDateFns}>
            <MobileDateTimePicker
                open={open}
                onClose={() => setOpen(false)}
                onOpen={() => setOpen(true)}
                maxDateTime={MAX_EDITED_CREATION_TIME}
                minDateTime={MIN_EDITED_CREATION_TIME}
                disabled={loading}
                DialogProps={{
                    sx: {
                        zIndex: '1502',
                        '.MuiPickersToolbar-penIconButton': {
                            display: 'none',
                        },
                    },
                }}
                value={value}
                onChange={handleChange}
                renderInput={(params) => (
                    <TextField
                        {...params}
                        hiddenLabel
                        margin="none"
                        variant="standard"
                    />
                )}
            />
        </LocalizationProvider>
    );
};

export default EnteDateTimePicker;
