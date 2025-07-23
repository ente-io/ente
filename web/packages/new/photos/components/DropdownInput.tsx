import {
    MenuItem,
    Select,
    type SelectChangeEvent,
    Typography,
} from "@mui/material";

/**
 * A label, and the associated value, shown in the {@link DropdownInput}.
 */
export interface DropdownOption<T> {
    label: string;
    value: T;
}

interface DropdownInputProps<T> {
    /**
     * The dropdown options.
     */
    options: DropdownOption<T>[];
    /**
     * The currently selected value, if any.
     */
    selected: T | undefined;
    /**
     * Callback invoked when the user changes the selected value.
     */
    onSelect: (selectedValue: T) => void;
    /**
     * An optional placeholder shown when there is no selected value.
     */
    placeholder?: string;
}

/**
 * A custom MUI {@link Select} with a look as per our designs, and with an
 * narrower interface focused on picking from a static list of options.
 *
 * This behaves as a controlled component - the caller is expected to set the
 * {@link selected} prop. The caller will then be notified of changes by calls
 * to the {@link onSelect} function.
 */
export const DropdownInput = <T extends string>({
    options,
    selected,
    onSelect,
    placeholder,
}: DropdownInputProps<T>) => (
    <Select
        value={selected}
        onChange={(event: SelectChangeEvent) => {
            onSelect(event.target.value as T);
        }}
        variant="outlined"
        displayEmpty
        renderValue={() => {
            // Return the value that is shown in the unexpanded state.
            const label = options.find((o) => o.value == selected)?.label;
            return label ? (
                // Wrap the label if doesn't fit.
                <Typography sx={{ whiteSpace: "normal" }}>{label}</Typography>
            ) : (
                <Typography sx={{ color: "text.muted" }}>
                    {placeholder}
                </Typography>
            );
        }}
        MenuProps={{
            slotProps: {
                paper: {
                    // Select component sets the min width of each element to
                    // the width of the select input's width, so setting the
                    // maxWidth to 0 forces element widths to equal minWidth.
                    sx: { maxWidth: 0 },
                },
                list: {
                    sx: {
                        backgroundColor: "background.paper2",
                        ".MuiMenuItem-root": {
                            color: "text.faint",
                            whiteSpace: "normal",
                        },
                        // Make the selected item pop out by using color.
                        "&&& > .Mui-selected": { color: "text.base" },
                    },
                },
            },
        }}
        sx={{
            // Remove the border in the quiescent state.
            ".MuiOutlinedInput-notchedOutline": { borderColor: "transparent" },
            // Give the default appearance a background fill, similar to our
            // text inputs.
            ".MuiSelect-select": { backgroundColor: "fill.faint" },
        }}
    >
        {options.map(({ value, label }) => (
            <MenuItem key={value} value={value}>
                <Typography>{label}</Typography>
            </MenuItem>
        ))}
    </Select>
);
