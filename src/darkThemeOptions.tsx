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
        MuiMenu: {
            styleOverrides: { paper: { margin: '10px' } },
        },
    },

    palette: {
        mode: 'dark',
        primary: {
            main: '#fff',
        },
        text: {
            primary: '#fff',
            secondary: '#808080',
        },
        accent: {
            main: '#43BA6C',
            dark: '#369556',
        },

        danger: {
            main: '#c93f3f',
        },
        background: { default: '#000000', paper: '#1b1b1b' },
        grey: {
            A100: '#ccc',
            A200: 'rgba(256, 256, 256, 0.24)',
        },
        divider: 'rgba(255, 255, 255, 0.24)',
    },
    shape: {
        borderRadius: 8,
    },
});

export default darkThemeOptions;
