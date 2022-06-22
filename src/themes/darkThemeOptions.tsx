import {
    createTheme,
    PaletteColor,
    PaletteColorOptions,
    TypeText,
} from '@mui/material/styles';

declare module '@mui/material/styles' {
    interface Palette {
        accent: PaletteColor;
        danger: PaletteColor;
        stroke: TypeText;
    }
    interface PaletteOptions {
        accent?: PaletteColorOptions;
        danger?: PaletteColorOptions;
        stroke?: Partial<TypeText>;
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

        MuiButton: {
            defaultProps: {
                variant: 'contained',
            },
            styleOverrides: {
                root: {
                    padding: '12px 16px',
                    borderRadius: '4px',
                },
                startIcon: {
                    marginRight: '12px',
                },
                sizeLarge: {
                    width: '100%',
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
    },

    palette: {
        mode: 'dark',
        primary: {
            main: '#f0f0f0',
        },
        secondary: {
            main: 'rgba(256, 256, 256, 0.1)',
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
        stroke: {
            primary: '#ffffff',
            secondary: 'rgba(256,256,256,0.24)',
            disabled: 'rgba(256,256,256,0.12)',
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
    typography: {
        body1: {
            fontSize: '16px',
            lineHeight: '20px',
        },
        body2: {
            fontSize: '14px',
            lineHeight: '17px',
        },
        button: {
            fontSize: '16px',
            lineHeight: '20px',
            fontWeight: 'bold',
            textTransform: 'none',
        },
        title: {
            fontSize: '32px',
            lineHeight: '40px',
            fontWeight: 'bold',
            display: 'block',
        },
        subtitle: {
            fontSize: '24px',
            fontWeight: 'bold',
            lineHeight: '36px',
            display: 'block',
        },
        caption: {
            display: 'block',
            fontSize: '12px',
            lineHeight: '15px',
        },
        h1: {
            fontSize: '36px',
            lineHeight: '44px',
        },
        h2: {
            fontSize: '30px',
            lineHeight: '36px',
        },
        h3: {
            fontSize: '24px',
            lineHeight: '29px',
        },
        h4: {
            fontSize: '18px',
            lineHeight: '22px',
        },

        fontFamily: ['Inter', 'sans-serif'].join(','),
    },
});

export default darkThemeOptions;
