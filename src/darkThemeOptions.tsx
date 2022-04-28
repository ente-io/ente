import { createTheme } from '@mui/material/styles';

declare module '@mui/material/styles' {
    interface Palette {
        accent: Palette['primary'];
        danger: Palette['primary'];
    }
    interface PaletteOptions {
        accent: PaletteOptions['primary'];
        danger: PaletteOptions['primary'];
    }
}

declare module '@mui/material/Button' {
    export interface ButtonPropsColorOverrides {
        danger: true;
    }
}

// Create a theme instance.
const darkThemeOptions = createTheme({
    components: {
        MuiPaper: {
            styleOverrides: { root: { backgroundImage: 'none' } },
        },
        MuiLink: {
            styleOverrides: {
                root: {
                    color: '#fff',
                    textDecoration: 'none',
                    '&:hover': {
                        color: '#fff',
                        textDecoration: 'underline',
                        textDecorationColor: '#fff',
                    },
                },
            },
        },
    },

    palette: {
        mode: 'dark',
        primary: {
            main: '#fff',
        },
        text: {
            primary: 'hsla(0, 0%, 100%, 1)',
            secondary: 'hsla(0, 0%, 100%, 0.5)',
        },
        accent: {
            main: '#43BA6C',
            dark: '#369556',
        },

        danger: {
            main: '#c93f3f',
        },
        background: { default: '#191919', paper: '#191919' },
    },
});

export default darkThemeOptions;
