import React from 'react';
import {
    MIN_EDITED_CREATION_TIME,
    MAX_EDITED_CREATION_TIME,
    ALL_TIME,
} from 'services/fileService';

import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';

const isSameDay = (first, second) =>
    first.getFullYear() === second.getFullYear() &&
    first.getMonth() === second.getMonth() &&
    first.getDate() === second.getDate();

const EnteDateTimePicker = ({ isInEditMode, pickedTime, handleChange }) => (
    <DatePicker
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
