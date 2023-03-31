import { PaletteOptions } from '@mui/material';
import darkThemeColors from 'themes/colors/dark';
import lightThemeColors from 'themes/colors/light';
import fixedColors from 'themes/colors/fixed';

const lightThemePalette: PaletteOptions = {
    mode: 'dark',
    primary: {
        main: lightThemeColors.fill.base,
        dark: lightThemeColors.fill.basePressed,
        contrastText: darkThemeColors.text.base,
    },
    secondary: {
        main: lightThemeColors.fill.faint,
        dark: lightThemeColors.fill.faintPressed,
        contrastText: lightThemeColors.text.base,
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
        default: lightThemeColors.background.base,
        paper: lightThemeColors.background.elevated,
        base: lightThemeColors.background.base,
        elevated: lightThemeColors.background.elevated,
        elevated2: lightThemeColors.background.elevated2,
    },
    text: {
        primary: lightThemeColors.text.base,
        secondary: lightThemeColors.text.muted,
        disabled: lightThemeColors.text.faint,
        base: lightThemeColors.text.base,
        muted: lightThemeColors.text.muted,
        faint: lightThemeColors.text.faint,
    },
    divider: lightThemeColors.stroke.faint,
};

export default lightThemePalette;
