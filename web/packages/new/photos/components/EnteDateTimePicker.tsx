import {
    LocalizationProvider,
    MobileDateTimePicker,
} from "@mui/x-date-pickers";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFnsV3";
import React, { useState } from "react";

interface EnteDateTimePickerProps {
    /**
     * The initial date to preselect in the date/time picker.
     *
     * If not provided, the current date/time is used.
     */
    initialValue?: Date;
    /**
     * If true, then the picker shows provided date/time but doesn't allow
     * editing it.
     */
    disabled?: boolean;
    /**
     * Callback invoked when the user makes and confirms a date/time.
     */
    onAccept: (date: Date) => void;
    /**
     * Optional callback invoked when the picker has been closed.
     */
    onClose?: () => void;
}

/**
 * A customized version of MUI DateTimePicker.
 */
export const EnteDateTimePicker: React.FC<EnteDateTimePickerProps> = ({
    initialValue,
    disabled,
    onAccept,
    onClose,
}) => {
    const [open, setOpen] = useState(true);
    const [value, setValue] = useState<Date | null>(initialValue ?? new Date());

    const handleAccept = (date: Date | null) => date && onAccept(date);

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
                disabled={disabled}
                minDateTime={new Date(1800, 0, 1)}
                disableFuture={true}
                onAccept={handleAccept}
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
