import { ThemeColorsOptions } from '@mui/material';
import { THEME_COLOR } from 'constants/theme';
import darkThemeColors from './dark';
import lightThemeColors from './light';
import fixedColors from './fixed';

export const getColors = (themeColor: THEME_COLOR): ThemeColorsOptions => {
    switch (themeColor) {
        case THEME_COLOR.LIGHT:
            return { ...fixedColors, ...lightThemeColors };
        default:
            return { ...fixedColors, ...darkThemeColors };
    }
};
