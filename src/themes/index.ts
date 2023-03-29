import { createTheme } from '@mui/material';
import { THEME_COLOR } from 'constants/theme';
import { getComponents } from './components';
import { getPallette } from './palette';
import { typography } from './typography';

export const getTheme = (themeColor: THEME_COLOR) => {
    const palette = getPallette(themeColor);
    const components = getComponents(palette, typography);
    const theme = createTheme({
        palette,
        typography,
        components,
    });
    return theme;
};
