import { PaletteOptions } from '@mui/material';
import darkThemeColors from 'themes/colors/dark';
import lightThemeColors from 'themes/colors/light';
import fixedColors from 'themes/colors/fixed';

const darkThemePalette: PaletteOptions = {
    mode: 'dark',
    primary: {
        main: darkThemeColors.fill.base,
        dark: darkThemeColors.fill.basePressed,
        contrastText: lightThemeColors.text.base,
    },
    secondary: {
        main: darkThemeColors.fill.faint,
        dark: darkThemeColors.fill.faintPressed,
        contrastText: darkThemeColors.text.base,
    },
    accent: {
        main: fixedColors.accent.A500,
        dark: fixedColors.accent.A700,
        contrastText: darkThemeColors.text.base,
    },
    critical: {
        main: fixedColors.warning.A700,
        dark: fixedColors.warning.A800,
        contrastText: darkThemeColors.text.base,
    },
    background: {
        default: darkThemeColors.background.base,
        paper: darkThemeColors.background.elevated,
        base: darkThemeColors.background.base,
        elevated: darkThemeColors.background.elevated,
        elevated2: darkThemeColors.background.elevated2,
    },
    text: {
        primary: darkThemeColors.text.base,
        secondary: darkThemeColors.text.muted,
        disabled: darkThemeColors.text.faint,
        base: darkThemeColors.text.base,
        muted: darkThemeColors.text.muted,
        faint: darkThemeColors.text.faint,
    },
    divider: darkThemeColors.stroke.faint,
};

export default darkThemePalette;
