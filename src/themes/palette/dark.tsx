import { BasePalette, PaletteOptions } from '@mui/material';

const darkThemePalette: Omit<PaletteOptions, keyof BasePalette> = {
    mode: 'dark',
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
        base: 'rgba(255, 255, 255)',
        muted: 'rgba(255, 255, 255, 0.16)',
        faint: 'rgba(255, 255, 255, 0.12)',
        basePressed: 'rgba(255, 255, 255, 0.90)',
        faintPressed: 'rgba(255, 255, 255, 0.60)',
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
                y: 2,
                blur: 12,
                color: 'rgba(0, 0, 0, 0.75)',
            },
        ],
        menu: [
            {
                y: 0,
                blur: 6,
                color: 'rgba(0, 0, 0, 0.50)',
            },
            {
                y: 2,
                blur: 12,
                color: 'rgba(0, 0, 0, 0.75)',
            },
        ],
        button: [
            {
                y: 4,
                blur: 4,
                color: 'rgba(0, 0, 0, 0.75)',
            },
        ],
    },
};

export default darkThemePalette;
