import { FixedColors, ThemeColorsOptions } from '@mui/material';

const fixedColors: Pick<ThemeColorsOptions, keyof FixedColors> = {
    accent: {
        A700: '#00B33C',
        A500: '#1DB954',
        A400: '#26CB5F',
        A300: '#01DE4D',
    },
    caution: {
        A500: '#FFC247',
    },
    warning: {
        A800: '#F53434',
        A700: '#EA3F3F',
        A500: '#FF6565',
        A400: '#FF6F6F',
    },
    blur: {
        base: 96,
        muted: 48,
        faint: 24,
    },

    white: { base: '#fff', muted: 'rgba(255, 255, 255, 0.48)' },
    black: { base: '#000', muted: 'rgba(0, 0, 0, 0.65)' },
};

export default fixedColors;
