import { createTheme } from '@mui/material/styles';

declare module '@mui/material/styles' {
    interface Palette {
        accent: Palette['primary'];
    }
    interface PaletteOptions {
        accent: PaletteOptions['primary'];
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
                    '&:hover': { color: '#51cd7c' },
                    textDecorationColor: '#fff',
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
        background: { default: '#191919', paper: '#191919' },
        grey: {
            A100: '#ccc',
            A200: '#777',
            A400: '#4E4E4E',
        },
    },
});

export default darkThemeOptions;
