import type { Shadow, ThemeColorsOptions } from "@mui/material";
import type { Components } from "@mui/material/styles/components";
import type { TypographyOptions } from "@mui/material/styles/createTypography";

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
                    backgroundColor: colors.backdrop?.faint,
                },
            },
        },
    },
    MuiDialog: {
        styleOverrides: {
            root: {
                ".MuiBackdrop-root": {
                    backgroundColor: colors.backdrop?.faint,
                },
                "& .MuiDialog-paper": {
                    filter: getDropShadowStyle(colors.shadows?.float),
                },
                // Reset the MUI default paddings to 16px everywhere.
                //
                // This is not a great choice either, usually most dialogs, for
                // one reason or the other, will need to customize this padding
                // anyway. But not resetting it to 16px leaves it at the MUI
                // defaults, which just don't work with our designs.
                "& .MuiDialogTitle-root": {
                    // MUI default is '16px 24px'.
                    padding: "16px",
                },
                "& .MuiDialogContent-root": {
                    // MUI default is '20px 24px'.
                    padding: "16px",
                    // If the contents of the dialog's contents exceed the
                    // available height, show a scrollbar just for the contents
                    // instead of the entire dialog.
                    overflowY: "auto",
                },
                "& .MuiDialogActions-root": {
                    // MUI default is way since they cluster the buttons to the
                    // right, our designs usually want the buttons to align with
                    // the heading / content.
                    padding: "16px",
                },
                ".MuiDialogTitle-root + .MuiDialogContent-root": {
                    // MUI resets this to 0 when the content doesn't use
                    // dividers (none of ours do). I feel that is a better
                    // default, since unlike margins, padding doesn't collapse,
                    // but changing this now would break existing layouts.
                    paddingTop: "16px",
                },
            },
        },
    },
    MuiPaper: {
        styleOverrides: { root: { backgroundImage: "none" } },
    },
    MuiLink: {
        defaultProps: {
            color: colors.accent?.A500,
            underline: "none",
        },
        styleOverrides: {
            root: {
                "&:hover": {
                    underline: "always",
                    color: colors.accent?.A500,
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
                fontSize: typography.body?.fontSize,
                lineHeight: typography.body?.lineHeight,
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

const getDropShadowStyle = (shadows: Shadow[] | undefined) => {
    return (shadows ?? [])
        .map(
            (shadow) =>
                `drop-shadow(${shadow.x}px ${shadow.y}px ${shadow.blur}px ${shadow.color})`,
        )
        .join(" ");
};

interface IconColorableOwnerState {
    color?: string;
    disabled?: boolean;
}

function getIconColor(
    ownerState: IconColorableOwnerState,
    colors: ThemeColorsOptions,
) {
    switch (ownerState.color) {
        case "primary":
            return {
                color: colors.stroke?.base,
            };
        case "secondary":
            return {
                color: colors.stroke?.muted,
            };
    }
    if (ownerState.disabled) {
        return {
            color: colors.stroke?.faint,
        };
    }
    return {};
}
