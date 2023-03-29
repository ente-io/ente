import { PaletteOptions } from '@mui/material';
import { THEME_COLOR } from 'constants/theme';
import darkThemePalette from 'themes/palette/dark';
import lightThemePalette from 'themes/palette/light';
import baseColorPalette from './base';

export const getPallette = (themeColor: THEME_COLOR): PaletteOptions => {
    switch (themeColor) {
        case THEME_COLOR.LIGHT:
            return { ...baseColorPalette, ...lightThemePalette };
        default:
            return { ...baseColorPalette, ...darkThemePalette };
    }
};
