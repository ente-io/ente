// TODO:
/* eslint-disable @typescript-eslint/no-unsafe-enum-comparison */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import type {
    FixedColors,
    PaletteOptions,
    Shadow,
    ThemeColorsOptions,
} from "@mui/material";
import { createTheme } from "@mui/material";
import type { Components } from "@mui/material/styles/components";
import type { TypographyOptions } from "@mui/material/styles/createTypography";

export enum THEME_COLOR {
    LIGHT = "light",
    DARK = "dark",
}

export const getTheme = (
    themeColor: THEME_COLOR,
    colorAccentType: ColorAccentType,
) => {
    const colors = getColors(themeColor, colorAccentType);
    const palette = getPallette(themeColor, colors);
    const components = getComponents(colors, typography);
    return createTheme({
        colors,
        palette,
        typography,
        components,
        shape: {
            // Increase the default border radius mulitplier from 4 to 8.
            borderRadius: 8,
        },
        transitions: {
            // Increase the default transition out duration from 195 to 300.
            duration: { leavingScreen: 300 },
        },
    });
};

export type ColorAccentType = "auth" | "photos";

const getColors = (
    themeColor: THEME_COLOR,
    accentType: ColorAccentType,
): ThemeColorsOptions => {
    switch (themeColor) {
        case THEME_COLOR.LIGHT:
            return { ...fixedColors(accentType), ...lightThemeColors };
        default:
            return { ...fixedColors(accentType), ...darkThemeColors };
    }
};

const fixedColors = (
    accentType: "auth" | "photos",
): Pick<ThemeColorsOptions, keyof FixedColors> => {
    switch (accentType) {
        case "auth":
            return {
                ...commonFixedColors,
                accent: authAccentColor,
            };
        default:
            return {
                ...commonFixedColors,
                accent: photosAccentColor,
            };
    }
};

const commonFixedColors: Partial<Pick<ThemeColorsOptions, keyof FixedColors>> =
    {
        accent: {
            A700: "#00B33C",
            A500: "#1DB954",
            A400: "#26CB5F",
            A300: "#01DE4D",
        },
        warning: {
            A500: "#FFC247",
        },
        danger: {
            A800: "#F53434",
            A700: "#EA3F3F",
            A500: "#FF6565",
            A400: "#FF6F6F",
        },
        white: { base: "#fff", muted: "rgba(255, 255, 255, 0.48)" },
        black: { base: "#000", muted: "rgba(0, 0, 0, 0.65)" },
    };

const authAccentColor = {
    A700: "rgb(164, 0, 182)",
    A500: "rgb(150, 13, 214)",
    A400: "rgb(122, 41, 193)",
    A300: "rgb(152, 77, 244)",
};

const photosAccentColor = {
    A700: "#00B33C",
    A500: "#1DB954",
    A400: "#26CB5F",
    A300: "#01DE4D",
};

const lightThemeColors: Omit<ThemeColorsOptions, keyof FixedColors> = {
    background: {
        base: "#fff",
        elevated: "#fff",
        elevated2: "rgba(153, 153, 153, 0.04)",
    },
    backdrop: {
        base: "rgba(255, 255, 255, 0.92)",
        muted: "rgba(255, 255, 255, 0.75)",
        faint: "rgba(255, 255, 255, 0.30)",
    },
    text: {
        base: "#000",
        muted: "rgba(0, 0, 0, 0.60)",
        faint: "rgba(0, 0, 0, 0.50)",
    },
    fill: {
        base: "#000",
        muted: "rgba(0, 0, 0, 0.12)",
        faint: "rgba(0, 0, 0, 0.04)",
        basePressed: "rgba(0, 0, 0, 0.87))",
        faintPressed: "rgba(0, 0, 0, 0.08)",
    },
    stroke: {
        base: "#000",
        muted: "rgba(0, 0, 0, 0.24)",
        faint: "rgba(0, 0, 0, 0.12)",
    },

    shadows: {
        float: [{ x: 0, y: 0, blur: 10, color: "rgba(0, 0, 0, 0.25)" }],
        menu: [
            {
                x: 0,
                y: 0,
                blur: 6,
                color: "rgba(0, 0, 0, 0.16)",
            },
            {
                x: 0,
                y: 3,
                blur: 6,
                color: "rgba(0, 0, 0, 0.12)",
            },
        ],
        button: [
            {
                x: 0,
                y: 4,
                blur: 4,
                color: "rgba(0, 0, 0, 0.25)",
            },
        ],
    },
};

const darkThemeColors: Omit<ThemeColorsOptions, keyof FixedColors> = {
    background: {
        base: "#000000",
        elevated: "#1b1b1b",
        elevated2: "#252525",
    },
    backdrop: {
        base: "rgba(0, 0, 0, 0.90)",
        muted: "rgba(0, 0, 0, 0.65)",
        faint: "rgba(0, 0, 0,0.20)",
    },
    text: {
        base: "#fff",
        muted: "rgba(255, 255, 255, 0.70)",
        faint: "rgba(255, 255, 255, 0.50)",
    },
    fill: {
        base: "#fff",
        muted: "rgba(255, 255, 255, 0.16)",
        faint: "rgba(255, 255, 255, 0.12)",
        basePressed: "rgba(255, 255, 255, 0.90)",
        faintPressed: "rgba(255, 255, 255, 0.06)",
    },
    stroke: {
        base: "#ffffff",
        muted: "rgba(255,255,255,0.24)",
        faint: "rgba(255,255,255,0.16)",
    },

    shadows: {
        float: [
            {
                x: 0,
                y: 2,
                blur: 12,
                color: "rgba(0, 0, 0, 0.75)",
            },
        ],
        menu: [
            {
                x: 0,
                y: 0,
                blur: 6,
                color: "rgba(0, 0, 0, 0.50)",
            },
            {
                x: 0,
                y: 3,
                blur: 6,
                color: "rgba(0, 0, 0, 0.25)",
            },
        ],
        button: [
            {
                x: 0,
                y: 4,
                blur: 4,
                color: "rgba(0, 0, 0, 0.75)",
            },
        ],
    },
};

const getPallette = (
    themeColor: THEME_COLOR,
    colors: ThemeColorsOptions,
): PaletteOptions => {
    const paletteOptions = getPalletteOptions(themeColor, colors);
    switch (themeColor) {
        case THEME_COLOR.LIGHT:
            return { mode: "light", ...paletteOptions };
        default:
            return { mode: "dark", ...paletteOptions };
    }
};

const getPalletteOptions = (
    themeColor: THEME_COLOR,
    colors: ThemeColorsOptions,
): PaletteOptions => {
    return {
        primary: {
            // See: [Note: strict mode migration]
            //
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            main: colors.fill.base,
            dark: colors.fill?.basePressed,
            contrastText:
                themeColor === "dark" ? colors.black?.base : colors.white?.base,
        },
        secondary: {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            main: colors.fill.faint,
            dark: colors.fill?.faintPressed,
            contrastText: colors.text?.base,
        },
        accent: {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            main: colors.accent.A500,
            dark: colors.accent?.A700,
            contrastText: colors.white?.base,
        },
        critical: {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            main: colors.danger.A700,
            dark: colors.danger?.A800,
            contrastText: colors.white?.base,
        },
        background: {
            default: colors.background?.base,
            paper: colors.background?.elevated,
        },
        text: {
            primary: colors.text?.base,
            secondary: colors.text?.muted,
            disabled: colors.text?.faint,
            base: colors.text?.base,
            muted: colors.text?.muted,
            faint: colors.text?.faint,
        },
        divider: colors.stroke?.faint,
    };
};

const typography: TypographyOptions = {
    // [Note: Font weights]
    //
    // We only use three font weights:
    //
    // - 500 (sx "regular", CSS "normal")
    // - 600 (sx "medium")
    // - 700 (sx "bold", CSS "bold")
    //
    // While the sx prop allows us to use keywords "regular", "medium" and
    // "bold", which we do elsewhere in the code, within this file those
    // keywords cannot be used in all contexts because they instead map to the
    // CSS keywords (which MUI can't and doesn't remap). To avoid any confusion,
    // within this file we only use the numeric values.
    //
    // ---
    //
    // MUI (as of v6) uses the following font weights by default:
    // - fontWeightLight 300
    // - fontWeightRegular 400
    // - fontWeightMedium 500
    // - fontWeightBold 700
    //
    // The browser default (CSS keyword "normal"), is also 400.
    //
    // However for Inter, the font that we use, 400 is too light, and to improve
    // legibility we change fontWeightRegular to 500.
    //
    // Correspondingly, we shift fontWeightMedium to 600. fontWeightBold then
    // ends up mapping back to 700, which also nicely coincides with the CSS
    // keyword "bold".
    //
    // MUI uses fontWeightLight only as the default font weight for the h1 and
    // h2 variants, but we override their font weight in our theme. Thus we
    // don't need to bother with the light variant (though for consistency of
    // specifying every value, we alias it the same weight as regular, 500).
    fontFamily: "Inter Variable, sans-serif",
    fontWeightLight: 500,
    fontWeightRegular: 500 /* CSS baseline reset sets this as the default */,
    fontWeightMedium: 600,
    fontWeightBold: 700,
    h1: {
        fontSize: "48px",
        lineHeight: "58px",
        fontWeight: 600 /* medium */,
    },
    h2: {
        fontSize: "32px",
        lineHeight: "39px",
        fontWeight: 500 /* Reset to regular to override MUI's default theme */,
    },
    h3: {
        fontSize: "24px",
        lineHeight: "29px",
        fontWeight: 600 /* medium */,
    },
    h4: {
        fontSize: "22px",
        lineHeight: "27px",
        fontWeight: 500 /* Reset to regular to override MUI's default theme */,
    },
    h5: {
        fontSize: "20px",
        lineHeight: "25px",
        fontWeight: 600 /* medium */,
    },
    // h6 is the default variant used by MUI's DialogTitle.
    h6: {
        // The font size and line height below is the same as large.
        fontSize: "18px",
        lineHeight: "22px",
        fontWeight: 600 /* medium */,
    },
    large: {
        fontSize: "18px",
        lineHeight: "22px",
    },
    body: {
        fontSize: "16px",
        lineHeight: "20px",
    },
    small: {
        fontSize: "14px",
        lineHeight: "17px",
    },
    mini: {
        fontSize: "12px",
        lineHeight: "15px",
    },
    tiny: {
        fontSize: "10px",
        lineHeight: "12px",
    },
};

const getComponents = (
    colors: ThemeColorsOptions,
    typography: TypographyOptions,
): Components => ({
    MuiCssBaseline: {
        styleOverrides: {
            body: {
                // MUI has different letter spacing for each variant, but those
                // are values arrived at for the default Material font, and
                // don't work for the font that we're using.
                //
                // So we reset the letter spacing for _all_ variants to a
                // reasonable value that works for our font.
                letterSpacing: "-0.011em",
            },
        },
    },

    MuiTypography: {
        defaultProps: {
            // MUI has body1 as the default variant for Typography, but our
            // variant scheme is different, instead of body1/2, we have
            // large/body/small etc. So reset the default to our equivalent of
            // body1, which is "body".
            variant: "body",
            // Map all our custom variants to <p>.
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
        defaultProps: {
            // This is required to prevent console errors about aria-hiding a
            // focused button when the dialog is closed.
            //
            // https://github.com/mui/material-ui/issues/43106#issuecomment-2314809028
            closeAfterTransition: false,
        },
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
                // defaults, which just doesn't work well with our designs.
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
                    // MUI default is way off for us since they cluster the
                    // buttons to the right, while our designs usually want the
                    // buttons to align with the heading / content.
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
            // Change the default button variant from "text" to "contained".
            variant: "contained",
        },
        styleOverrides: {
            // We don't use the size prop for the MUI button, or rather it
            // cannot be used, since we have fixed the paddings and font sizes
            // unconditionally here (which is all that the size prop changes).
            root: {
                padding: "12px 16px",
                borderRadius: "4px",
                textTransform: "none",
                // Body, but medium.
                fontSize: typography.body?.fontSize,
                lineHeight: typography.body?.lineHeight,
                fontWeight: 600,
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
        },
    },
    MuiInputBase: {
        styleOverrides: {
            formControl: {
                // Give a symmetric border to the input field, by default the
                // border radius is only applied to the top for the "filled"
                // variant of input used inside TextFields.
                borderRadius: "8px",
                // TODO: Should we also add overflow hidden so that there is no
                // gap between the filled area and the (full width) border. Not
                // sure how this might interact with selects.
                // overflow: "hidden",

                // Hide the bottom border that always appears for the "filled"
                // variant of input used inside TextFields.
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
            // The MUI default variant is "outlined", override it to use the
            // "filled" one by default.
            variant: "filled",
            // Reduce the vertical margins that MUI adds to the TextField.
            //
            // Note that this causes things to be too tight when the helper text
            // is shown, so this is not recommended for new code that we write.
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
                // Set a default border radius for all snackbar's (e.g.
                // notification popups).
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
