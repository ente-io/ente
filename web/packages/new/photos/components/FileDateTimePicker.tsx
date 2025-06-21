import {
    LocalizationProvider,
    MobileDateTimePicker,
} from "@mui/x-date-pickers";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import dayjs, { Dayjs } from "dayjs";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import type { ParsedMetadataDate } from "ente-media/file-metadata";
import React, { useState } from "react";

interface FileDateTimePickerProps {
    /**
     * The initial date to preselect in the date/time picker.
     *
     * If not provided, the current date/time is used.
     */
    initialValue?: Date;
    /**
     * Callback invoked when the user makes and confirms a date/time.
     */
    onAccept: (date: ParsedMetadataDate) => void;
    /**
     * Optional callback invoked when the picker has been closed.
     *
     * > Note: This is only informational, for the caller to update their state.
     * > The picker has already been closed at this point.
     */
    onDidClose?: () => void;
}

/**
 * A customized version of MUI DateTimePicker suitable for use in selecting and
 * modifying the date/time for a photo.
 *
 * On success, it returns a {@link ParsedMetadataDate} which contains the a
 * local date/time string representation of the selected date, the current UTC
 * offset, and an epoch timestamp. The idea is that the user is picking a
 * date/time in the hypothetical timezone of where the photo was taken.
 *
 * We return local (current) UTC offset, but this might be different from what
 * the user is imagining when they're picking a date. So it should be taken as
 * an advisory, and only used if the photo does not already have an associated
 * UTC offset. For more discussion of the caveats and nuances around this, see
 * [Note: Photos are always in local date/time].
 */
export const FileDateTimePicker: React.FC<FileDateTimePickerProps> = ({
    initialValue,
    onAccept,
    onDidClose,
}) => {
    const [open, setOpen] = useState(true);
    const [value, setValue] = useState<Dayjs | null>(dayjs(initialValue));

    const isSmallWidth = useIsSmallWidth();

    const handleAccept = (d: Dayjs | null) => {
        if (!dayjs.isDayjs(d))
            throw new Error(`Unexpected non-dayjs result ${typeof d}`);
        onAccept(parseMetadataDateFromDayjs(d));
    };

    const handleClose = () => {
        setOpen(false);
        onDidClose?.();
    };

    return (
        <LocalizationProvider dateAdapter={AdapterDayjs}>
            <MobileDateTimePicker
                value={value}
                onChange={(d) => setValue(d)}
                open={open}
                onClose={handleClose}
                onOpen={() => setOpen(true)}
                disableFuture={true}
                /* The dialog grows too big on the default portrait mode with
                   our theme customizations. So we instead use the landscape
                   layout if the screen is large enough. */
                orientation={isSmallWidth ? "portrait" : "landscape"}
                onAccept={handleAccept}
                slots={{ field: EmptyField }}
                slotProps={{
                    /* The time picker has a smaller height than the calendar,
                       which causes an ungainly layout shift. Prevent this by
                       giving a minimum height to the picker.

                       The constant 336px will likely change in the future when
                       MUI gets updated, so this solution is fragile. However
                       MUI is anyways intending to replace the TimeClock with a
                       DigitalTimePicker that has a better UX. */
                    layout: {
                        sx: { ".MuiTimeClock-root": { minHeight: "336px" } },
                    },
                }}
            />
        </LocalizationProvider>
    );
};

/**
 * We don't wish to render any UI for the MUI DateTimePicker when it is closed,
 * and instead only wish to use it as a dialog that we trigger ourselves.
 *
 * To achieve this we provide this nop-DOM element as the "field" slot to the
 * date/time picker.
 *
 * See: https://mui.com/x/react-date-pickers/custom-field/
 */
const EmptyField: React.FC = () => <></>;

/**
 * A variant of {@link parseMetadataDate} that does the same thing, but for
 * {@link Dayjs} instances.
 */
const parseMetadataDateFromDayjs = (d: Dayjs): ParsedMetadataDate => {
    // `Dayjs.format` returns an ISO 8601 string of the form
    // 2020-04-02T08:02:17-05:00'.
    //
    // https://day.js.org/docs/en/display/format
    //
    // This is different from the JavaScript `Date.toISOString` which also
    // returns an ISO 8601 string, but with the time zone descriptor always set
    // to UTC Zulu ("Z").
    //
    // The behaviour of Dayjs.format is more convenient for us, since it does
    // both things we wish for:
    // - Display the date in the local timezone
    // - Include the timezone offset.

    const s = d.format();

    let dateTime: string;
    let offset: string | undefined;

    // Check to see if there is a time-zone descriptor of the form "Z" or
    // "±05:30" or "±0530" at the end of s.
    const m = /Z|[+-]\d\d:?\d\d$/.exec(s);
    if (m?.index) {
        dateTime = s.substring(0, m.index);
        offset = s.substring(m.index);
    } else {
        throw new Error(
            `Dayjs.format returned a string "${s}" without a timezone offset`,
        );
    }

    const timestamp = d.valueOf() * 1000;

    return { dateTime, offset, timestamp };
};
