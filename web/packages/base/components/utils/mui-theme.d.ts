import type { PaletteColor } from "@mui/material";
import React from "react";

// Import the module augmentation that provides types for `theme.vars.*`.
import type {} from "@mui/material/themeCssVarsAugmentation";

// Add new tokens to the Palette.
//
// https://mui.com/material-ui/customization/css-theme-variables/usage/#adding-new-theme-tokens

declare module "@mui/material/styles" {
    /**
     * Add "paper2" the "background" color tokens, giving us:
     *
     * - background.default
     * - background.paper
     * - background.paper2
     */
    interface TypeBackground {
        /**
         * A second level elevation, indicating a paper within a paper.
         */
        paper2: string;
    }

    /**
     * Define a new set of tokens for the "text" color in the palette which
     * matches the strength triads we use for stroke and fill.
     *
     * Since there is no way to override or replace the existing tokens, we can
     * only augment the interface with our new tokens. However, our code should
     * NOT use the default tokens provided by MUI:
     *
     * - text.primary   <- Don't use
     * - text.secondary <- Don't use
     * - text.disabled  <- Don't use
     *
     * Instead, use these three:
     *
     * - text.base
     * - text.muted
     * - text.faint
     */
    interface TypeText {
        base: string;
        muted: string;
        faint: string;
    }

    interface Palette {
        /**
         * The main brand color. e.g. the "Ente green", the "Auth purple".
         *
         * This does not vary with the color scheme.
         */
        accent: PaletteColor;
        /**
         * The color for potentially dangerous actions, errors, or other things
         * we would like to call the user's attention out to.
         *
         * MUI has an "error" palette color, but that seems to semantically not
         * gel with all uses. e.g. it feels weird to create a button with
         * color="error".
         *
         * This does not vary with the color scheme.
         */
        critical: PaletteColor;
        /**
         * Neutral tranparent colors for the stroke of icons and other outlines.
         *
         * These change with the color scheme.
         *
         * They come in three strengths which are meant to play nicely with the
         * corresponding strengths of "text.*" and "fill.*".
         */
        stroke: {
            base: string;
            muted: string;
            faint: string;
        };
        /**
         * Neutral transparent colors for filling small areas like icon or
         * button backgrounds.
         *
         * These change with the color scheme.
         *
         * They come in three strengths which are meant to play nicely with the
         * corresponding strengths of "text.*" and "stroke.*", plus extra ones.
         *
         * Some strengths also have a hover variant, useful to indicate hover on
         * buttons and menu items that use the corresponding fill.
         */
        fill: {
            base: string;
            baseHover: string;
            muted: string;
            faint: string;
            faintHover: string;
            fainter: string;
        };
        /**
         * Transparent background fills that serve as the backdrop of modals,
         * dialogs and drawers etc.
         *
         * These change with the color scheme.
         */
        backdrop: {
            base: string;
            muted: string;
            faint: string;
        };
        /**
         * Various ad-hoc fixed colors used by our designs.
         *
         * These do not change with the color scheme.
         */
        fixed: {
            white: string;
            black: string;
            /**
             * Various fixed shades of gray.
             * TODO(LM) - audit and rename.
             */
            gray: {
                A: string;
                /**
                 * - Color of check on hovering on image thumbnail during
                 *   selection.
                 */
                B: string;
                /**
                 * - Background of check on hovering on image thumbnail during
                 *   selection.
                 *
                 * - Color of check on image thumbnail when it is selected.
                 */
                E: string;
            };
            /**
             * The color of a switch when it is enabled.
             */
            switchOn: string;
            /**
             * The transparent overlay on top of the region that will be cropped
             * during image editing.
             */
            croppedAreaOverlay: string;
            /**
             * Color of overlaid icons on top of thumbnails. e.g. color of the
             * "archived" indicator shown on top of albums.
             */
            overlayIndicatorMuted: string;
            /**
             * Color of the total space in the usage bar on the storage card.
             */
            storageCardUsageFill: string;
        };
        /**
         * MUI as of v6 does not allow customizing shadows easily. This is due
         * for change: https://github.com/mui/material-ui/issues/44291.
         *
         * Meanwhile use a custom variable. Since it is specific to the color
         * scheme, keep it inside the palette.
         */
        boxShadow: {
            /**
             * Drop shadow for "big" floating elements like {@link Dialog}.
             */
            float: string;
            /** Currently unused. */
            menu: string;
            /** Currently unused. */
            button: string;
        };
    }

    interface PaletteOptions {
        accent?: Palette["accent"];
        critical?: Palette["critical"];
        stroke?: Palette["stroke"];
        fill?: Palette["fill"];
        backdrop?: Palette["backdrop"];
        fixed?: Palette["fixed"];
        boxShadow?: Palette["boxShadow"];
    }
}

// Make our custom palette colors available for use as the color prop of various
// MUI components.

declare module "@mui/material/Button" {
    interface ButtonPropsColorOverrides {
        // Turn off MUI provided palette colors we don't use.
        error: false;
        success: false;
        info: false;
        warning: false;
        inherit: false;
        // Add our custom palette colors.
        accent: true;
        critical: true;
    }
}

declare module "@mui/material/IconButton" {
    interface IconButtonPropsColorOverrides {
        // Turn off MUI provided palette colors we don't use.
        error: false;
        success: false;
        info: false;
        warning: false;
        inherit: false;
    }
}

declare module "@mui/material/Checkbox" {
    interface CheckboxPropsColorOverrides {
        accent: true;
    }
}

declare module "@mui/material/Switch" {
    interface SwitchPropsColorOverrides {
        accent: true;
    }
}

declare module "@mui/material/SvgIcon" {
    interface SvgIconPropsColorOverrides {
        accent: true;
    }
}

declare module "@mui/material/CircularProgress" {
    interface CircularProgressPropsColorOverrides {
        accent: true;
    }
}

// Tell TypeScript about our Typography variants
//
// https://mui.com/material-ui/customization/typography/#adding-amp-disabling-variants

declare module "@mui/material/styles" {
    interface TypographyVariants {
        body: React.CSSProperties;
        small: React.CSSProperties;
        mini: React.CSSProperties;
        tiny: React.CSSProperties;
    }

    interface TypographyVariantsOptions {
        body?: React.CSSProperties;
        small?: React.CSSProperties;
        mini?: React.CSSProperties;
        tiny?: React.CSSProperties;
    }
}

declare module "@mui/material/Typography" {
    // Update the Typography's variant prop options.
    interface TypographyPropsVariantOverrides {
        // Turn off MUI provided variants we don't use.
        subtitle1: false;
        subtitle2: false;
        body1: false;
        body2: false;
        caption: false;
        button: false;
        overline: false;
        // Add our custom variants.
        body: true;
        small: true;
        mini: true;
        tiny: true;
    }
}
