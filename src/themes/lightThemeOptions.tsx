import {
    createTheme,
    PaletteColor,
    PaletteColorOptions,
    TypeText,
} from '@mui/material/styles';

declare module '@mui/material/styles' {
    interface TypeBackground {
        overPaper?: string;
    }

    interface BlurStrength {
        base: string;
        muted: string;
        faint: string;
    }
    interface BlurStrengthOptions {
        base?: string;
        muted?: string;
        faint?: string;
    }
    interface Palette {
        accent: PaletteColor;
        fill: PaletteColor;
        backdrop: PaletteColor;
        blur: BlurStrength;
        danger: PaletteColor;
        stroke: TypeText;
    }
    interface PaletteOptions {
        accent?: PaletteColorOptions;
        danger?: PaletteColorOptions;
        fill?: PaletteColorOptions;
        backdrop?: PaletteColorOptions;
        blur?: BlurStrengthOptions;
        stroke?: Partial<TypeText>;
    }

    interface TypographyVariants {
        title: React.CSSProperties;
        subtitle: React.CSSProperties;
        mini: React.CSSProperties;
    }

    interface TypographyVariantsOptions {
        title?: React.CSSProperties;
        subtitle?: React.CSSProperties;
        mini?: React.CSSProperties;
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

declare module '@mui/material/CircularProgress' {
    export interface CircularProgressPropsColorOverrides {
        accent: true;
    }
}

// Create a theme instance.
const lightThemeOptions = createTheme({
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

        MuiDrawer: {
            styleOverrides: {
                root: {
                    '.MuiBackdrop-root': {
                        backgroundColor: 'rgba(255,255,255,0.75)',
                    },
                },
            },
        },
        MuiDialog: {
            styleOverrides: {
                root: {
                    '.MuiBackdrop-root': {
                        backgroundColor: 'rgba(255,255,255,0.75)',
                    },
                    '& .MuiDialog-paper': {
                        boxShadow: '0px 0px 10px 0px rgba(153,153,153,0.04)',
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
                color: '#1db954',
                underline: 'none',
            },
            styleOverrides: {
                root: {
                    '&:hover': {
                        underline: 'always',
                        color: '#1db954',
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
                    '&& >svg': {
                        fontSize: '20px',
                    },
                },
                endIcon: {
                    marginLeft: '12px',
                    '&& >svg': {
                        fontSize: '20px',
                    },
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
                                color: '#000000',
                            };
                        case 'secondary':
                            return {
                                color: 'rgba(0,0,0,0.24)',
                            };
                        case 'disabled':
                            return {
                                color: 'rgba(0, 0, 0, 0.12)',
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
                                color: '#000000',
                            };
                        case 'secondary':
                            return {
                                color: 'rgba(0,0,0,0.24)',
                            };
                    }
                    if (ownerState.disabled) {
                        return {
                            color: 'rgba(0, 0, 0, 0.12)',
                        };
                    }
                },
            },
        },
        MuiSnackbar: {
            styleOverrides: {
                root: {
                    borderRadius: '8px',
                },
            },
        },
    },

    palette: {
        mode: 'light',
        primary: {
            main: '#000',
            contrastText: '#fff',
        },
        secondary: {
            main: 'rgba(0, 0, 0, 0.04)',
            contrastText: '#000',
        },
        accent: {
            main: '#1DB954',
            dark: '#00B33C',
            light: '#26CB5F',
        },
        fill: {
            main: 'rgba(0, 0, 0, 0.12)',
            dark: 'rgba(0, 0, 0, 0.04)',
            light: 'rgba(0, 0, 0)',
        },
        backdrop: {
            main: 'rgba(255, 255, 255, 0.75)',
            light: 'rgba(255, 255, 255, 0.3)',
        },

        blur: {
            base: '96px',
            muted: '48px',
            faint: '24px',
        },
        text: {
            primary: '#000',
            secondary: 'rgba(0, 0, 0, 0.6)',
            disabled: 'rgba(0, 0, 0, 0.5)',
        },

        danger: {
            main: '#EA3f3f',
        },
        stroke: {
            primary: '#000000',
            secondary: 'rgba(0,0,0,0.24)',
            disabled: 'rgba(0,0,0,0.12)',
        },
        background: {
            default: '#ffffff',
            paper: '#ffffff',
            overPaper: ' rgba(153,153,153,0.04)',
        },
        grey: {
            A100: '#ccc',
            A200: 'rgba(255, 255, 255, 0.24)',
            A400: '#434343',
            500: 'rgba(255, 255, 255, 0.5)',
        },
        divider: 'rgba(0, 0, 0, 0.12)',
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
        mini: {
            fontSize: '10px',
            lineHeight: '12px',
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
            fontSize: '48px',
            lineHeight: '58px',
        },
        h2: {
            fontSize: '36px',
            lineHeight: '44px',
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

export default lightThemeOptions;
