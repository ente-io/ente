import { createTheme } from '@mui/material/styles';

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
            main: '#51cd7c',
        },
        text: {
            primary: '#fff',
            secondary: '#777',
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
