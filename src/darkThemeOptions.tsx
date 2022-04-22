import { createTheme } from '@mui/material/styles';

// Create a theme instance.
const darkThemeOptions = createTheme({
    palette: {
        mode: 'dark',
        primary: {
            main: '#fff',
        },
        text: {
            primary: '#fff',
            secondary: '#777',
        },
        background: { default: '#191919', paper: '#202020' },
        grey: {
            A200: '#777',
            A400: '#4E4E4E',
        },
    },
});

export default darkThemeOptions;
