import React, { useState } from 'react';
import { THEMES } from 'types/theme';
import ThemeToggler from './ThemeToggler';

export default function ThemeSwitcher() {
    const [theme, setTheme] = useState<THEMES>(THEMES.DARK);

    return <ThemeToggler theme={theme} setTheme={setTheme} />;
}
