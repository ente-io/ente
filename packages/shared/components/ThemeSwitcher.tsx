import { ToggleButton, ToggleButtonGroup } from '@mui/material';
import React from 'react';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import { THEME_COLOR } from '@ente/shared/themes/constants';
interface Iprops {
    themeColor: THEME_COLOR;
    setThemeColor: (theme: THEME_COLOR) => void;
}
export default function ThemeSwitcher({ themeColor, setThemeColor }: Iprops) {
    const handleChange = (event, themeColor: THEME_COLOR) => {
        if (themeColor !== null) {
            setThemeColor(themeColor);
        }
    };

    return (
        <ToggleButtonGroup
            size="small"
            value={themeColor}
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
