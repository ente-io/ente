import { FixedColors, ThemeColorsOptions } from '@mui/material';

const darkThemeColors: Omit<ThemeColorsOptions, keyof FixedColors> = {
    background: {
        base: '#000000',
        elevated: '#1b1b1b',
        elevated2: '#252525',
    },
    backdrop: {
        base: 'rgba(0, 0, 0, 0.90)',
        muted: 'rgba(0, 0, 0, 0.65)',
        faint: 'rgba(0, 0, 0,0.20)',
    },
    text: {
        base: '#fff',
        muted: 'rgba(255, 255, 255, 0.70)',
        faint: 'rgba(255, 255, 255, 0.50)',
    },
    fill: {
        base: '#fff',
        muted: 'rgba(255, 255, 255, 0.16)',
        faint: 'rgba(255, 255, 255, 0.12)',
        basePressed: 'rgba(255, 255, 255, 0.90)',
        faintPressed: 'rgba(255, 255, 255, 0.06)',
        strong: 'rgba(255, 255, 255, 0.32)',
    },
    stroke: {
        base: '#ffffff',
        muted: 'rgba(255,255,255,0.24)',
        faint: 'rgba(255,255,255,0.16)',
        fainter: 'rgba(255,255,255,0.08)',
    },

    shadows: {
        float: [
            {
                x: 0,
                y: 2,
                blur: 12,
                color: 'rgba(0, 0, 0, 0.75)',
            },
        ],
        menu: [
            {
                x: 0,
                y: 0,
                blur: 6,
                color: 'rgba(0, 0, 0, 0.50)',
            },
            {
                x: 0,
                y: 2,
                blur: 12,
                color: 'rgba(0, 0, 0, 0.75)',
            },
        ],
        button: [
            {
                x: 0,
                y: 4,
                blur: 4,
                color: 'rgba(0, 0, 0, 0.75)',
            },
        ],
    },
};

export default darkThemeColors;
