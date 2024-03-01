import { Shadow, ThemeColorsOptions } from "@mui/material";
import { Components } from "@mui/material/styles/components";
import { TypographyOptions } from "@mui/material/styles/createTypography";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const getComponents = (
    colors: ThemeColorsOptions,
    typography: TypographyOptions,
): Components => ({
    MuiCssBaseline: {
        styleOverrides: {
            body: {
                fontFamily: typography.fontFamily,
                letterSpacing: "-0.011em",
            },
            strong: { fontWeight: 700 },
        },
    },

    MuiTypography: {
        defaultProps: {
            variant: "body",
            variantMapping: {
                large: "p",
                body: "p",
                small: "p",
                mini: "p",
                tiny: "p",
            },
        },
    },

    MuiDrawer: {
        styleOverrides: {
            root: {
                ".MuiBackdrop-root": {
                    backgroundColor: colors.backdrop.faint,
                },
            },
        },
    },
    MuiDialog: {
        styleOverrides: {
            root: {
                ".MuiBackdrop-root": {
                    backgroundColor: colors.backdrop.faint,
                },
                "& .MuiDialog-paper": {
                    filter: getDropShadowStyle(colors.shadows.float),
                },
                "& .MuiDialogTitle-root": {
                    padding: "16px",
                },
                "& .MuiDialogContent-root": {
                    padding: "16px",
                    overflowY: "overlay",
                },
                "& .MuiDialogActions-root": {
                    padding: "16px",
                },
                ".MuiDialogTitle-root + .MuiDialogContent-root": {
                    paddingTop: "16px",
                },
            },
        },
        defaultProps: {
            fullWidth: true,
            maxWidth: "sm",
        },
    },
    MuiPaper: {
        styleOverrides: { root: { backgroundImage: "none" } },
    },
    MuiLink: {
        defaultProps: {
            color: colors.accent.A500,
            underline: "none",
        },
        styleOverrides: {
            root: {
                "&:hover": {
                    underline: "always",
                    color: colors.accent.A500,
                },
            },
        },
    },

    MuiButton: {
        defaultProps: {
            variant: "contained",
        },
        styleOverrides: {
            root: {
                padding: "12px 16px",
                borderRadius: "4px",
                textTransform: "none",
                fontWeight: "bold",
                fontSize: typography.body.fontSize,
                lineHeight: typography.body.lineHeight,
            },
            startIcon: {
                marginRight: "12px",
                "&& >svg": {
                    fontSize: "20px",
                },
            },
            endIcon: {
                marginLeft: "12px",
                "&& >svg": {
                    fontSize: "20px",
                },
            },
            sizeLarge: {
                width: "100%",
            },
        },
    },
    MuiInputBase: {
        styleOverrides: {
            formControl: {
                borderRadius: "8px",
                "::before": {
                    borderBottom: "none !important",
                },
            },
        },
    },
    MuiFilledInput: {
        styleOverrides: {
            input: {
                "&:autofill": {
                    boxShadow: "#c7fd4f",
                },
            },
        },
    },
    MuiTextField: {
        defaultProps: {
            variant: "filled",
            margin: "dense",
        },
        styleOverrides: {
            root: {
                "& .MuiInputAdornment-root": {
                    marginRight: "8px",
                },
            },
        },
    },
    MuiSvgIcon: {
        styleOverrides: {
            root: ({ ownerState }) => ({
                ...getIconColor(ownerState, colors),
            }),
        },
    },

    MuiIconButton: {
        styleOverrides: {
            root: ({ ownerState }) => ({
                ...getIconColor(ownerState, colors),
                padding: "12px",
            }),
        },
    },
    MuiSnackbar: {
        styleOverrides: {
            root: {
                borderRadius: "8px",
            },
        },
    },
    MuiModal: {
        styleOverrides: {
            root: {
                '&:has(> div[style*="opacity: 0"])': {
                    pointerEvents: "none",
                },
            },
        },
    },
    MuiMenuItem: {
        styleOverrides: {
            // don't reduce opacity of disabled items
            root: {
                "&.Mui-disabled": {
                    opacity: 1,
                },
            },
        },
    },
});

const getDropShadowStyle = (shadows: Shadow[]) => {
    return shadows
        .map(
            (shadow) =>
                `drop-shadow(${shadow.x}px ${shadow.y}px ${shadow.blur}px ${shadow.color})`,
        )
        .join(" ");
};

function getIconColor(ownerState, colors: ThemeColorsOptions) {
    switch (ownerState.color) {
        case "primary":
            return {
                color: colors.stroke.base,
            };
        case "secondary":
            return {
                color: colors.stroke.muted,
            };
    }
    if (ownerState.disabled) {
        return {
            color: colors.stroke.faint,
        };
    }
}
