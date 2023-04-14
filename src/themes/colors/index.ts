import { ThemeColorsOptions } from '@mui/material';
import { THEME_COLOR } from 'constants/theme';
import darkThemeColors from './dark';
import lightThemeColors from './light';
import { APPS } from 'constants/apps';
import { getFixesColors } from './fixed';

export const getColors = (
    themeColor: THEME_COLOR,
    appName: APPS
): ThemeColorsOptions => {
    switch (themeColor) {
        case THEME_COLOR.LIGHT:
            return { ...getFixesColors(appName), ...lightThemeColors };
        default:
            return { ...getFixesColors(appName), ...darkThemeColors };
    }
};
