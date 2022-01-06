import React from 'react';

import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import {
    MIN_EDITED_CREATION_TIME,
    MAX_EDITED_CREATION_TIME,
    ALL_TIME,
} from 'constants/file';

const isSameDay = (first, second) =>
    first.getFullYear() === second.getFullYear() &&
    first.getMonth() === second.getMonth() &&
    first.getDate() === second.getDate();

interface Props {
    loading?: boolean;
    isInEditMode: boolean;
    pickedTime: Date;
    handleChange: (date: Date) => void;
}

const EnteDateTimePicker = ({
    loading,
    isInEditMode,
    pickedTime,
    handleChange,
}: Props) => (
    <DatePicker
        disabled={loading}
        open={isInEditMode}
        selected={pickedTime}
        onChange={handleChange}
        timeInputLabel="Time:"
        dateFormat="dd/MM/yyyy h:mm aa"
        showTimeSelect
        autoFocus
        minDate={MIN_EDITED_CREATION_TIME}
        maxDate={MAX_EDITED_CREATION_TIME}
        maxTime={
            isSameDay(pickedTime, new Date())
                ? MAX_EDITED_CREATION_TIME
                : ALL_TIME
        }
        minTime={MIN_EDITED_CREATION_TIME}
        fixedHeight
        withPortal></DatePicker>
);

export default EnteDateTimePicker;
