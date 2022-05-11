import { createTheme } from '@mui/material/styles';

// Create a theme instance.
const darkThemeOptions = createTheme({
    components: {
        MuiPaper: {
            styleOverrides: { root: { backgroundImage: 'none' } },
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
        background: { default: '#191919', paper: '#303030' },
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
