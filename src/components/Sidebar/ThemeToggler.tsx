import { ToggleButton, ToggleButtonGroup } from '@mui/material';
import React from 'react';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import { THEMES } from './InfoSection';
interface Iprops {
    theme: THEMES;
    setTheme: (theme: THEMES) => void;
}
export default function ThemeToggler({ theme, setTheme }: Iprops) {
    const handleChange = (event, theme: THEMES) => {
        setTheme(theme);
    };

    return (
        <ToggleButtonGroup
            color="primary"
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
