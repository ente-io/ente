import { useState } from "react";

import {
    LocalizationProvider,
    MobileDateTimePicker,
} from "@mui/x-date-pickers";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import {
    MAX_EDITED_CREATION_TIME,
    MIN_EDITED_CREATION_TIME,
} from "constants/file";

interface Props {
    initialValue?: Date;
    disabled?: boolean;
    label?: string;
    onSubmit: (date: Date) => void;
    onClose?: () => void;
}

const EnteDateTimePicker = ({
    initialValue,
    disabled,
    onSubmit,
    onClose,
}: Props) => {
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
                maxDateTime={MAX_EDITED_CREATION_TIME}
                minDateTime={MIN_EDITED_CREATION_TIME}
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

export default EnteDateTimePicker;
