import ExpandMore from '@mui/icons-material/ExpandMore';
import {
    MenuItem,
    Select,
    SelectChangeEvent,
    Stack,
    Typography,
} from '@mui/material';

interface Option {
    label: string;
    value: string;
}

interface Iprops {
    label: string;
    options: Option[];
    message?: string;
    selectedValue: string;
    setSelectedValue: (selectedValue: string) => void;
    placeholder: string;
}
const DropdownInput = ({
    label,
    options,
    message,
    selectedValue,
    placeholder,
    setSelectedValue,
}: Iprops) => {
    return (
        <Stack spacing={'4px'}>
            <Typography color={'inherit'}>{label}</Typography>
            <Select
                IconComponent={ExpandMore}
                displayEmpty
                variant="standard"
                MenuProps={{
                    MenuListProps: {
                        sx: (theme) => ({
                            backgroundColor: theme.palette.background.overPaper,
                            '.MuiMenuItem-root ': {
                                color: theme.palette.text.secondary,
                            },
                            '&& > .Mui-selected': {
                                background: theme.palette.background.overPaper,
                                color: theme.palette.text.primary,
                            },
                        }),
                    },
                }}
                sx={(theme) => ({
                    '::before , ::after': {
                        borderBottom: 'none !important',
                    },
                    '.MuiSelect-select': {
                        background: theme.palette.fill.dark,
                        borderRadius: '8px',
                        p: '12px',
                    },
                    '.MuiSelect-icon': {
                        mr: '12px',
                    },
                })}
                renderValue={(selected) =>
                    selected?.length === 0 ? placeholder : selected
                }
                value={selectedValue}
                onChange={(event: SelectChangeEvent) => {
                    console.log(event);
                    setSelectedValue(event.target.value);
                }}>
                {options.map((option, index) => (
                    <MenuItem
                        key={option.label}
                        divider={index !== options.length - 1}
                        value={option.value}
                        sx={{
                            px: '16px',
                            py: '14px',
                            color: (theme) => theme.palette.primary.main,
                        }}>
                        {option.label}
                    </MenuItem>
                ))}
            </Select>
            {message && (
                <Typography px={'8px'} color={'text.secondary'}>
                    {message}
                </Typography>
            )}
        </Stack>
    );
};

export default DropdownInput;
