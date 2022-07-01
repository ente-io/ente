import {
    createTheme,
    PaletteColor,
    PaletteColorOptions,
    TypeText,
} from '@mui/material/styles';

declare module '@mui/material/styles' {
    interface Palette {
        accent: PaletteColor;
        fill: PaletteColor;
        danger: PaletteColor;
        stroke: TypeText;
    }
    interface PaletteOptions {
        accent?: PaletteColorOptions;
        danger?: PaletteColorOptions;
        fill?: PaletteColorOptions;
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

declare module '@mui/material/SvgIcon' {
    interface SvgIconPropsColorOverrides {
        accent: true;
    }
}

declare module '@mui/material/Alert' {
    export interface AlertPropsColorOverrides {
        accent: true;
    }
}

// Create a theme instance.
const darkThemeOptions = createTheme({
    components: {
        MuiCssBaseline: {
            styleOverrides: {
                body: {
                    fontFamily: ['Inter', 'sans-serif'].join(','),
                    letterSpacing: '-0.011em',
                },
                strong: { fontWeight: 900 },
            },
        },
        MuiDialog: {
            styleOverrides: {
                root: {
                    '& .MuiDialog-paper': {
                        boxShadow: '0px 0px 10px 0px rgba(0, 0, 0, 0.25)',
                    },
                    '& .MuiDialogTitle-root': {
                        padding: '16px',
                    },
                    '& .MuiDialogContent-root': {
                        padding: '16px',
                        overflowY: 'overlay',
                    },
                    '& .MuiDialogActions-root': {
                        padding: '16px',
                    },
                    '.MuiDialogTitle-root + .MuiDialogContent-root': {
                        paddingTop: '16px',
                    },
                },
            },
            defaultProps: {
                fullWidth: true,
                maxWidth: 'sm',
            },
        },
        MuiPaper: {
            styleOverrides: { root: { backgroundImage: 'none' } },
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
        MuiInputBase: {
            styleOverrides: {
                formControl: {
                    borderRadius: '8px',
                    '::before': {
                        borderBottom: 'none !important',
                    },
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
            styleOverrides: {
                root: {
                    '& .MuiInputAdornment-root': {
                        marginRight: '8px',
                    },
                },
            },
        },
        MuiSvgIcon: {
            styleOverrides: {
                root: ({ ownerState }) => {
                    switch (ownerState.color) {
                        case 'primary':
                            return {
                                color: '#ffffff',
                            };
                        case 'secondary':
                            return {
                                color: 'rgba(256,256,256,0.24)',
                            };
                        case 'disabled':
                            return {
                                color: 'rgba(255, 255, 255, 0.12)',
                            };
                    }
                },
            },
        },

        MuiIconButton: {
            styleOverrides: {
                root: ({ ownerState }) => {
                    switch (ownerState.color) {
                        case 'primary':
                            return {
                                color: '#ffffff',
                            };
                        case 'secondary':
                            return {
                                color: 'rgba(256,256,256,0.24)',
                            };
                    }
                    if (ownerState.disabled) {
                        return {
                            color: 'rgba(255, 255, 255, 0.12)',
                        };
                    }
                },
            },
        },
    },

    palette: {
        mode: 'dark',
        primary: {
            main: '#fff',
            contrastText: '#000',
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
        fill: {
            main: 'rgba(256, 256, 256, 0.2)',
            dark: 'rgba(256, 256, 256, 0.1)',
            light: 'rgba(256, 256, 256)',
        },
        text: {
            primary: '#fff',
            secondary: 'rgba(255, 255, 255, 0.7)',
            disabled: 'rgba(255, 255, 255, 0.5)',
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
            lineHeight: '19px',
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
