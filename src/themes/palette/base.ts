import { BasePalette, PaletteOptions } from '@mui/material';

// Create a theme instance.
const baseColorPalette: Pick<PaletteOptions, keyof BasePalette> = {
    accent: {
        700: '#00B33C',
        500: '#1DB954',
        400: '#26CB5F',
        300: '#01DE4D',
    },
    caution: {
        500: '#FFC247',
    },
    danger: {
        800: '#F53434',
        700: '#EA3F3F',
        500: '#FF6565',
        400: '#FF6F6F',
    },
    blur: {
        base: 96,
        muted: 48,
        faint: 24,
    },

    white: { base: '#fff', muted: 'rgba(255, 255, 255, 0.48)' },
    black: '#000',
};

export default baseColorPalette;
