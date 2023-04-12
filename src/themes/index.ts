import { createTheme } from '@mui/material';
import { THEME_COLOR } from 'constants/theme';
import { getColors } from './colors';
import { getComponents } from './components';
import { getPallette } from './palette';
import { typography } from './typography';

export const getTheme = (themeColor: THEME_COLOR) => {
    const colors = getColors(themeColor);
    const palette = getPallette(themeColor);
    const components = getComponents(colors, typography);
    const theme = createTheme({
        colors,
        palette,
        typography,
        components,
        shape: {
            borderRadius: 8,
        },
    });
    return theme;
};
