import { ToggleButton, ToggleButtonGroup } from '@mui/material';
import React from 'react';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import { THEMES } from 'types/theme';
interface Iprops {
    theme: THEMES;
    setTheme: (theme: THEMES) => void;
}
export default function ThemeSwitcher({ theme, setTheme }: Iprops) {
    const handleChange = (event, theme: THEMES) => {
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
            <ToggleButton value={THEMES.LIGHT}>
                <LightModeIcon />
            </ToggleButton>
            <ToggleButton value={THEMES.DARK}>
                <DarkModeIcon />
            </ToggleButton>
        </ToggleButtonGroup>
    );
}
