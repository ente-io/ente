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

    interface TypographyVariants {
        title: React.CSSProperties;
        subtitle: React.CSSProperties;
    }

    interface TypographyVariantsOptions {
        title?: React.CSSProperties;
        subtitle?: React.CSSProperties;
    }
}

declare module '@mui/material/Button' {
    export interface ButtonPropsColorOverrides {
        accent: true;
        danger: true;
    }
}
declare module '@mui/material/Checkbox' {
    export interface CheckboxPropsColorOverrides {
        accent: true;
    }
}

declare module '@mui/material/Typography' {
    interface TypographyPropsVariantOverrides {
        title: true;
        subtitle: true;
    }
}

declare module '@mui/material/Switch' {
    interface SwitchPropsColorOverrides {
        accent: true;
    }
}

// Create a theme instance.
const darkThemeOptions = createTheme({
    components: {
        MuiPaper: {
            styleOverrides: { root: { backgroundImage: 'none' } },
        },
        MuiCssBaseline: {
            styleOverrides: {
                body: {
                    fontFamily: ['Inter', 'sans-serif'].join(','),
                    letterSpacing: '-0.011em',
                },
                strong: { fontWeight: 900 },
            },
        },
        MuiLink: {
            defaultProps: {
                underline: 'always',
            },
            styleOverrides: {
                root: {
                    '&:hover': {
                        color: '#1dba54',
                    },
                },
            },
        },
        MuiMenu: {
            styleOverrides: {
                paper: { margin: '10px' },
                list: {
                    padding: 0,
                    border: 'none',
                },
            },
        },

        MuiButton: {
            defaultProps: {
                variant: 'contained',
            },
            styleOverrides: {
                root: {
                    textTransform: 'none',
                    borderRadius: '8px',
                },
                sizeLarge: {
                    fontSize: '18px',
                    lineHeight: '21.78px',
                    padding: '16px',
                },
            },
        },

        MuiFilledInput: {
            styleOverrides: {
                input: {
                    '&:autofill': {
                        boxShadow: '#c7fd4f',
                    },
                },
            },
        },
        MuiTextField: {
            defaultProps: {
                variant: 'filled',
                margin: 'dense',
            },
        },
        MuiTypography: {
            styleOverrides: {
                body1: {
                    paddingBottom: '4px',
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
            500: 'rgba(256, 256, 256, 0.5)',
        },
        divider: 'rgba(256, 256, 256, 0.12)',
    },
    shape: {
        borderRadius: 8,
    },
    typography: {
        body1: {
            fontSize: '16px',
            lineHeight: '24px',
        },
        body2: {
            fontSize: '14px',
            lineHeight: '20px',
        },
        title: {
            fontSize: '32px',
            lineHeight: '40px',
            fontWeight: 600,
            display: 'block',
        },
        subtitle: {
            fontSize: '24px',
            fontWeight: 600,
            lineHeight: '36px',
            display: 'block',
        },
        caption: {
            fontSize: '12px',
            lineHeight: '15px',
        },
        fontFamily: ['Inter', 'sans-serif'].join(','),
    },
});

export default darkThemeOptions;
