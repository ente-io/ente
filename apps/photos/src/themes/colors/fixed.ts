import { FixedColors, ThemeColorsOptions } from '@mui/material';
import { APPS } from 'constants/apps';

export const getFixesColors = (
    appName: APPS
): Pick<ThemeColorsOptions, keyof FixedColors> => {
    switch (appName) {
        case APPS.AUTH:
            return {
                ...commonFixedColors,
                accent: authAccentColor,
            };
        default:
            return {
                ...commonFixedColors,
                accent: photosAccentColor,
            };
    }
};

const commonFixedColors: Partial<Pick<ThemeColorsOptions, keyof FixedColors>> =
    {
        accent: {
            A700: '#00B33C',
            A500: '#1DB954',
            A400: '#26CB5F',
            A300: '#01DE4D',
        },
        warning: {
            A500: '#FFC247',
        },
        danger: {
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

const authAccentColor = {
    A700: 'rgb(164, 0, 182)',
    A500: 'rgb(150, 13, 214)',
    A400: 'rgb(122, 41, 193)',
    A300: 'rgb(152, 77, 244)',
};

const photosAccentColor = {
    A700: '#00B33C',
    A500: '#1DB954',
    A400: '#26CB5F',
    A300: '#01DE4D',
};
