import {
    createTheme,
    PaletteColor,
    PaletteColorOptions,
} from '@mui/material/styles';

declare module '@mui/material/styles' {
    interface Palette {
        accent: PaletteColor;
        danger: PaletteColor;
    }
    interface PaletteOptions {
        accent?: PaletteColorOptions;
        danger?: PaletteColorOptions;
    }
}

declare module '@mui/material/Button' {
    export interface ButtonPropsColorOverrides {
        accent: true;
        danger: true;
    }
}

declare module '@mui/material/ToggleButtonGroup' {
    export interface ToggleButtonGroupPropsColorOverrides {
        negative: true;
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
                    textDecoration: 'none',
                    '&:hover': {
                        textDecoration: 'underline',
                    },
                },
            },
        },
        MuiMenu: {
            styleOverrides: { paper: { margin: '10px' } },
        },
        MuiButton: {
            defaultProps: {
                variant: 'contained',
            },
            styleOverrides: {
                root: {
                    fontSize: '18px',
                    lineHeight: '21.78px',
                    padding: '16px',
                    textTransform: 'none',
                    borderRadius: '8px',
                },
            },
        },
        MuiDialog: {
            styleOverrides: {
                paper: {
                    '& .MuiDialogActions-root': {
                        padding: '32px 24px',
                    },
                },
                root: {
                    '& .MuiDialogActions-root button': {
                        marginLeft: '16px',
                    },
                },
            },
        },
    },

    palette: {
        mode: 'dark',
        primary: {
            main: '#f0f0f0',
        },
        secondary: {
            main: 'rgba(256, 256, 256, 0.12)',
            contrastText: '#fff',
        },
        text: {
            primary: '#fff',
            secondary: '#808080',
        },
        accent: {
            main: '#1dba54',
            dark: '#248546',
            light: '#2cd366',
        },

        danger: {
            main: '#c93f3f',
        },
        background: { default: '#000000', paper: '#1b1b1b' },
        grey: {
            A100: '#ccc',
            A200: 'rgba(256, 256, 256, 0.24)',
            A400: '#434343',
        },
        divider: 'rgba(256, 256, 256, 0.12)',
    },
    shape: {
        borderRadius: 8,
    },
});

export default darkThemeOptions;
