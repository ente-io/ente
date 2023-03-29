import { PaletteOptions } from '@mui/material';
import { Components } from '@mui/material/styles/components';
import { TypographyOptions } from '@mui/material/styles/createTypography';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const getComponents = (
    palette: PaletteOptions,
    typography: TypographyOptions
): Components => ({
    MuiCssBaseline: {
        styleOverrides: {
            body: {
                fontFamily: typography.fontFamily,
                letterSpacing: '-0.011em',
            },
            strong: { fontWeight: 900 },
        },
    },

    MuiTypography: {
        defaultProps: {
            variant: 'body',
        },
    },

    MuiDrawer: {
        styleOverrides: {
            root: {
                '.MuiBackdrop-root': {
                    backgroundColor: palette.backdrop.faint,
                },
            },
        },
    },
    MuiDialog: {
        styleOverrides: {
            root: {
                '.MuiBackdrop-root': {
                    backgroundColor: palette.backdrop.faint,
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
            color: palette.primary[500],
            underline: 'none',
        },
        styleOverrides: {
            root: {
                '&:hover': {
                    underline: 'always',
                    color: palette.primary[500],
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
                            color: palette.stroke.base,
                        };
                    case 'secondary':
                        return {
                            color: palette.stroke.muted,
                        };
                    case 'disabled':
                        return {
                            color: palette.stroke.faint,
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
                            color: palette.stroke.base,
                        };
                    case 'secondary':
                        return {
                            color: palette.stroke.muted,
                        };
                }
                if (ownerState.disabled) {
                    return {
                        color: palette.stroke.faint,
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
});
