import {
    LocalizationProvider,
    MobileDateTimePicker,
} from "@mui/x-date-pickers";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import React, { useState } from "react";

interface EnteDateTimePickerProps {
    initialValue?: Date;
    /**
     * If true, then the picker shows the date/time but doesn't allow editing.
     */
    disabled?: boolean;
    label?: string;
    onSubmit: (date: Date) => void;
    onClose?: () => void;
}

export const EnteDateTimePicker: React.FC<EnteDateTimePickerProps> = ({
    initialValue,
    disabled,
    onSubmit,
    onClose,
}) => {
    const [open, setOpen] = useState(true);
    const [value, setValue] = useState(initialValue ?? new Date());

    const handleClose = () => {
        setOpen(false);
        onClose?.();
    };

    return (
        <LocalizationProvider dateAdapter={AdapterDateFns}>
            <MobileDateTimePicker
                value={value}
                onChange={setValue}
                open={open}
                onClose={handleClose}
                onOpen={() => setOpen(true)}
                minDateTime={new Date(1800, 0, 1)}
                maxDateTime={new Date()}
                disabled={disabled}
                onAccept={onSubmit}
                DialogProps={{
                    sx: {
                        zIndex: "1502",
                        ".MuiPickersToolbar-penIconButton": {
                            display: "none",
                        },
                        ".MuiDialog-paper": { width: "320px" },
                        ".MuiClockPicker-root": {
                            position: "relative",
                            minHeight: "292px",
                        },
                        ".PrivatePickersSlideTransition-root": {
                            minHeight: "200px",
                        },
                    },
                }}
                renderInput={() => <></>}
            />
        </LocalizationProvider>
    );
};
