import type { AppName } from "@/base/app";
import type { Theme } from "@mui/material";
import { createTheme } from "@mui/material";
import type { Components } from "@mui/material/styles/components";
import type { TypographyOptions } from "@mui/material/styles/createTypography";

const getTheme = (appName: AppName): Theme => {
    const colors = getColors(appName);
    const colorSchemes = getColorSchemes(colors);
    return createTheme({
        cssVariables: true,
        colorSchemes,
        typography,
        components,
        shape: {
            // Increase the default border radius multiplier from 4 to 8.
            borderRadius: 8,
        },
        transitions: {
            // Increase the default transition out duration from 195 to 300.
            duration: { leavingScreen: 300 },
        },
    });
};

/**
 * [Note: Colors]
 *
 * The word "color" in MUI stands for different things. In particular, the color
 * prop for (e.g.) a Button is not the same as the color passed in the sx prop.
 *
 * There are three layers (only the first is necessary, rest are semantic):
 *
 * 1. Consider some color, say a shade of red. This will be represented by its
 *    exact CSS color value, say "#ee0000".
 *
 * 2. These can be groups of color values that have roughly the same hue, but
 *    different levels of saturation. Such hue groups are arranged together into
 *    a "Colors" exported by "@/mui/material":
 *
 *        export interface Color {
 *            50: string;
 *            100: string;
 *            ...
 *            800: string;
 *            900: string;
 *            A100: string;
 *            ...
 *            A700: string;
 *        }
 *
 *  3. Finally, there are "PaletteColors" (the naming of props, and
 *     documentation within MUI (as of v6), omits the palette qualifier).
 *
 *         export interface PaletteColor {
 *             light: string;
 *             main: string;
 *             dark: string;
 *             contrastText: string;
 *         }
 *
 * The PaletteColors are what we use in the MUI component props (e.g. Button).
 * The PaletteColors are defined by providing color values for the four "tokens"
 * that make them up, either directly ("#aa000") or via Colors ("red[500]").
 *
 * Within the sx prop we need to specify a color value, which can come from the
 * palette. The "palette", as defined by the palette property we provide when
 * creating the theme, can consist of arbitrary (and nestable) key value pairs.
 *
 * Within sx prop, the "color" and "backgroundColor" props can refer to paths
 * inside this palette object. That is,
 *
 *         sx={{ color: "foo.bar" }}
 *
 * resolves to theme.vars.palette.foo.bar.
 *
 * [Note: Color names]
 *
 * When defining color names, there is some attempt at trying to use MUI v6,
 * which uses MD (Material Design) v2, nomenclature when feasible (just to keep
 * the number of concepts low), but as such, our color names should not be
 * thought of as following Material Design, and should be treated as arbitrary
 * tokens reflecting our own design system.
 *
 * Some callouts:
 *
 * - Our "primary" and "secondary" are neutral grays instead of the two-tone
 *   primary and secondary in MD. Our "accent" is corresponds to the MD primary.
 *
 * - Our "critical" is similar to and the alternative for the MD error (which is
 *   not used).
 *
 * - Two of the other default MD PaletteColors - warning, success - are used
 *   rarely, while info is not used at all.
 *
 * [Note: Theme and palette custom variables]
 *
 * Custom variables can be added to both the top level theme object, and to the
 * palette object within the theme. One would imagine that within the palette
 * there would only be colors that follow PaletteColor, but that's not something
 * MUI itself follows.
 *
 * So there is no particular reason to place custom color related variables in
 * theme vs in the palette. As a convention:
 *
 * - Custom colors (even if they're not PaletteColors) go within the palette.
 *
 * - Non-color tokens that depend on the color scheme (e.g. box shadows) also go
 *   within the palette so that they can be made color scheme specific.
 *
 * - All other custom variables remain within the top level theme.
 */
const getColors = (appName: AppName) => ({
    ..._colors,
    ...{
        accent: appName == "auth" ? _colors.accentAuth : _colors.accentPhotos,
    },
});

/**
 * The color values.
 *
 * Use this arbitrarily shaped object to define the palette. This avoid
 * duplication across color schemes, and also helps see if there are any
 * reusable colors.
 */
const _colors = {
    accentPhotos: {
        dark: "#00B33C",
        main: "#1DB954",
        light: "#01DE4D",
    },
    accentAuth: {
        dark: "rgb(164, 0, 182)",
        main: "rgb(150, 13, 214)",
        light: "rgb(152, 77, 244)",
    },
    fixed: {
        white: "#fff",
        black: "#000",
        success: "#1DB954",
        warning: "#FFC247",
        danger: {
            dark: "#F53434",
            main: "#EA3F3F",
            light: "#FF6565",
        },
        overlayIndicatorMuted: "rgba(255, 255, 255, 0.48)",
    },
    light: {
        background: {
            base: "#fff",
            paper: "#fff",
            paper2: "rgba(153, 153, 153, 0.04)",
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
        boxShadow: {
            float: "0px 0px 10px rgba(0, 0, 0, 0.25)",
            menu: "0px 0px 6px rgba(0, 0, 0, 0.16), 0px 3px 6px rgba(0, 0, 0, 0.12)",
            button: "0px 4px 4px rgba(0, 0, 0, 0.25)",
        },
    },
    dark: {
        background: {
            base: "#000000",
            paper: "#1b1b1b",
            paper2: "#252525",
        },
        backdrop: {
            base: "rgba(0, 0, 0, 0.90)" /* unused */,
            muted: "rgba(0, 0, 0, 0.65)" /* unused */,
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
        boxShadow: {
            float: "0px 2px 12px rgba(0, 0, 0, 0.75)",
            menu: "0px 0px 6px rgba(0, 0, 0, 0.50), 0px 3px 6px rgba(0, 0, 0, 0.25)",
            button: "0px 4px 4px rgba(0, 0, 0, 0.75)",
        },
    },
};

const getColorSchemes = (colors: ReturnType<typeof getColors>) => ({
    // light: false,
    dark: {
        palette: {
            primary: {
                main: colors.dark.fill.base,
                dark: colors.dark.fill.basePressed,
                contrastText: colors.fixed.white,
            },
            secondary: {
                main: colors.dark.fill.faint,
                dark: colors.dark.fill.faintPressed,
                contrastText: colors.dark.text.base,
            },
            success: { main: colors.fixed.success },
            warning: { main: colors.fixed.warning },
            accent: {
                main: colors.accent.main,
                dark: colors.accent.dark,
                light: colors.accent.light,
                contrastText: colors.fixed.white,
            },
            critical: {
                main: colors.fixed.danger.main,
                dark: colors.fixed.danger.dark,
                light: colors.fixed.danger.light,
                contrastText: colors.fixed.white,
            },
            background: {
                default: colors.dark.background.base,
                paper: colors.dark.background.paper,
                paper2: colors.dark.background.paper2,
            },
            text: {
                // Alias the tokens used by MUI to the ones that we use. This way,
                // we don't need to change the default ("primary"), or update the
                // MUI internal styling that refers to these tokens.
                //
                // Our own code should not use these.
                primary: colors.dark.text.base,
                secondary: colors.dark.text.muted,
                disabled: colors.dark.text.faint,
                // Our color tokens.
                base: colors.dark.text.base,
                muted: colors.dark.text.muted,
                faint: colors.dark.text.faint,
            },
            fill: {
                base: colors.dark.fill.base,
                muted: colors.dark.fill.muted,
                faint: colors.dark.fill.faint,
                faintHover: colors.dark.fill.faintPressed,
            },
            stroke: {
                base: colors.dark.stroke.base,
                muted: colors.dark.stroke.muted,
                faint: colors.dark.stroke.faint,
            },
            divider: colors.dark.stroke.faint,
            fixed: colors.fixed,
            backdrop: {
                base: colors.dark.backdrop.base,
                muted: colors.dark.backdrop.muted,
                faint: colors.dark.backdrop.faint,
            },
            boxShadow: colors.dark.boxShadow,
        },
    },
});

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

const components: Components = {
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
                body: "p",
                small: "p",
                mini: "p",
                tiny: "p",
            },
        },
    },

    MuiModal: {
        styleOverrides: {
            root: {
                // A workaround to prevent stuck modals from blocking clicks.
                // https://github.com/mui/material-ui/issues/32286#issuecomment-1287951109
                '&:has(> div[style*="opacity: 0"])': {
                    pointerEvents: "none",
                },
            },
        },
    },

    MuiDrawer: {
        styleOverrides: {
            root: {
                ".MuiBackdrop-root": {
                    backgroundColor: "var(--mui-palette-backdrop-faint)",
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
                    backgroundColor: "var(--mui-palette-backdrop-faint)",
                },
                "& .MuiDialog-paper": {
                    boxShadow: "var(--mui-palette-boxShadow-float)",
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
        // MUI applies a semi-transparent background image for elevation in dark
        // mode. Remove it to match the Paper background from our design.
        styleOverrides: { root: { backgroundImage: "none" } },
    },

    MuiLink: {
        defaultProps: {
            color: "var(--mui-palette-accent-main)",
            underline: "none",
        },
        styleOverrides: {
            root: {
                "&:hover": {
                    underline: "always",
                    color: "var(--mui-palette-accent-main)",
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

    MuiCheckbox: {
        defaultProps: {
            // Disable the ripple effect for all checkboxes.
            disableRipple: true,
        },
        styleOverrides: {
            // Since we've disabled the ripple, add other affordances to it (a
            // background and outline) to clearly indicate whenever it gains
            // keyboard focus.
            root: {
                "&.Mui-focusVisible": {
                    backgroundColor: "var(--mui-palette-fill-faint)",
                    outline: "1px solid var(--mui-palette-stroke-faint)",
                },
            },
        },
    },

    MuiSvgIcon: {
        styleOverrides: {
            root: {
                variants: [
                    {
                        props: { color: "primary" },
                        style: { color: "var(--mui-palette-stroke-base)" },
                    },
                    {
                        props: { color: "secondary" },
                        style: { color: "var(--mui-palette-stroke-muted)" },
                    },
                ],
            },
        },
    },

    MuiIconButton: {
        styleOverrides: {
            root: {
                padding: "12px",
                variants: [
                    {
                        props: { color: "primary" },
                        style: { color: "var(--mui-palette-stroke-base)" },
                    },
                    {
                        props: { color: "secondary" },
                        style: { color: "var(--mui-palette-stroke-muted)" },
                    },
                    {
                        props: { color: "disabled" },
                        style: { color: "var(--mui-palette-stroke-faint)" },
                    },
                ],
            },
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
};

// Exports ---

/**
 * The MUI {@link Theme} to use for the photos app.
 *
 * This is also the "default" theme, in that it is used for the accounts app
 * which serves both photos and auth.
 */
export const photosTheme = getTheme("photos");

/**
 * The MUI {@link Theme} to use for the auth app.
 */
export const authTheme = getTheme("auth");
