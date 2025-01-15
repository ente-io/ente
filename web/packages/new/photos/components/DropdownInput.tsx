import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import {
    Box,
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
        displayEmpty
        renderValue={() => {
            // Return the value that is shown in the unexpanded state.
            const label = options.find((o) => o.value == selected)?.label;
            return label ? (
                <Typography>{label}</Typography>
            ) : (
                <Typography sx={{ color: "text.muted" }}>
                    {placeholder}
                </Typography>
            );
        }}
    >
        {options.map((option, index) => (
            <MenuItem
                key={option.value}
                // divider={index !== options.length - 1}
                // value={option.value}
                // sx={{ px: "16px", py: "14px" }}
            >
                {/* <Typography>{option.label}</Typography> */}
                {option.label}
            </MenuItem>
        ))}
    </Select>
);

export const DropdownInput2 = <T extends string>({
    options,
    selected,
    onSelect,
    placeholder,
}: DropdownInputProps<T>) => (
    <Select
        IconComponent={ExpandMoreIcon}
        displayEmpty
        variant="standard"
        MenuProps={{
            PaperProps: {
                sx: {
                    // Select component automatically sets the min width of the element to the width
                    // of the select input's width, so setting the maxWidth to 0, forces to element
                    // width to equal to minWidth
                    maxWidth: 0,
                },
            },
            MenuListProps: {
                sx: {
                    backgroundColor: "background.paper2",
                    ".MuiMenuItem-root ": {
                        color: "text.faint",
                        whiteSpace: "normal",
                    },
                    // Make the selected item pop out by giving it a
                    // different color instead of giving it a different
                    // background color.
                    "&&& > .Mui-selected": {
                        backgroundColor: "background.paper2",
                        color: "text.base",
                    },
                },
            },
        }}
        sx={{
            "::before , ::after": {
                borderBottom: "none !important",
            },
            ".MuiInput-root": {
                backgroundColor: "fill.faint",
                borderRadius: "8px",
            },
            ".MuiSelect-select": {
                backgroundColor: "fill.faint",
                borderRadius: "8px",
            },
            "&&& .MuiSelect-select": {
                p: "12px 36px 12px 16px",
            },
            ".MuiSelect-icon": {
                mr: "12px",
                color: "stroke.muted",
            },
        }}
        renderValue={(selected) => {
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            return !selected?.length ? (
                <Box sx={{ color: "text.muted" }}>{placeholder ?? ""}</Box>
            ) : (
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                options.find((o) => o.value === selected).label
            );
        }}
        value={selected}
        onChange={(event: SelectChangeEvent) => {
            onSelect(event.target.value as T);
        }}
    >
        {options.map((option, index) => (
            <MenuItem
                key={option.value}
                divider={index !== options.length - 1}
                value={option.value}
                sx={{ px: "16px", py: "14px" }}
            >
                <Typography>{option.label}</Typography>
            </MenuItem>
        ))}
    </Select>
);
