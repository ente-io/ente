import { ThemeColorsOptions } from '@mui/material';
import { THEME_COLOR } from '../constants';
import darkThemeColors from './dark';
import lightThemeColors from './light';
import { APPS } from '@ente/shared/apps/constants';
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
