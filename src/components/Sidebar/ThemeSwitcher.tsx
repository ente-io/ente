import { ToggleButton, ToggleButtonGroup } from '@mui/material';
import React from 'react';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import { THEME_COLOR } from 'constants/theme';
interface Iprops {
    theme: THEME_COLOR;
    setTheme: (theme: THEME_COLOR) => void;
}
export default function ThemeSwitcher({ theme, setTheme }: Iprops) {
    const handleChange = (event, theme: THEME_COLOR) => {
        if (theme !== null) {
            setTheme(theme);
        }
    };

    return (
        <ToggleButtonGroup
            size="small"
            value={theme}
            exclusive
            onChange={handleChange}>
            <ToggleButton value={THEME_COLOR.LIGHT}>
                <LightModeIcon />
            </ToggleButton>
            <ToggleButton value={THEME_COLOR.DARK}>
                <DarkModeIcon />
            </ToggleButton>
        </ToggleButtonGroup>
    );
}
