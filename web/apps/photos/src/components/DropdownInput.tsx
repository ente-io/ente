import { isSxArray } from "@/base/components/utils/sx";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import {
    Box,
    MenuItem,
    Select,
    SelectChangeEvent,
    Stack,
    Typography,
    type TypographyProps,
} from "@mui/material";

export interface DropdownOption<T> {
    label: string;
    value: T;
}

interface Iprops<T> {
    label: string;
    labelSxProps?: TypographyProps["sx"];
    options: DropdownOption<T>[];
    message?: string;
    messageSxProps?: TypographyProps["sx"];
    selected: T;
    setSelected: (selectedValue: T) => void;
    placeholder?: string;
}

export default function DropdownInput<T extends string>({
    label,
    labelSxProps,
    options,
    message,
    selected,
    placeholder,
    setSelected,
    messageSxProps,
}: Iprops<T>) {
    return (
        <Stack spacing={"4px"}>
            <Typography sx={labelSxProps ?? {}}>{label}</Typography>
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
                    return !selected?.length ? (
                        <Box sx={{ color: "text.muted" }}>
                            {placeholder ?? ""}
                        </Box>
                    ) : (
                        options.find((o) => o.value === selected).label
                    );
                }}
                value={selected}
                onChange={(event: SelectChangeEvent) => {
                    setSelected(event.target.value as T);
                }}
            >
                {options.map((option, index) => (
                    <MenuItem
                        key={option.value}
                        divider={index !== options.length - 1}
                        value={option.value}
                        sx={(theme) => ({
                            px: "16px",
                            py: "14px",
                            color: theme.palette.primary.main,
                        })}
                    >
                        {option.label}
                    </MenuItem>
                ))}
            </Select>
            {message && (
                <Typography
                    variant="small"
                    sx={[
                        { px: "8px", color: "text.muted" },
                        ...(isSxArray(messageSxProps)
                            ? messageSxProps
                            : [messageSxProps]),
                    ]}
                >
                    {message}
                </Typography>
            )}
        </Stack>
    );
}
