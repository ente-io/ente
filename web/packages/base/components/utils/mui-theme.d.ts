import type { PaletteColor, PaletteColorOptions } from "@mui/material";
import React from "react";

declare module "@mui/material/styles" {
    interface Theme {
        colors: ThemeColors;
    }

    interface ThemeOptions {
        colors?: ThemeColorsOptions;
    }

    interface TypeText {
        base: string;
        muted: string;
        faint: string;
    }
}

declare module "@mui/material/Button" {
    interface ButtonPropsColorOverrides {
        accent: true;
        critical: true;
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
        critical: true;
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

// =================================================
// Custom Interfaces
// =================================================

declare module "@mui/material/styles" {
    interface ThemeColors {
        background: BackgroundType;
        backdrop: Strength;
        text: Strength;
        fill: FillStrength;
        stroke: Strength;
        shadows: Shadows;
        accent: ColorStrength;
        warning: ColorStrength;
        danger: ColorStrength;
        white: Omit<Strength, "faint">;
        black: Omit<Strength, "faint">;
    }

    interface ThemeColorsOptions {
        background?: Partial<BackgroundType>;
        backdrop?: Partial<Strength>;
        text?: Partial<Strength>;
        fill?: Partial<FillStrength>;
        stroke?: Partial<StrokeStrength>;
        shadows?: Partial<Shadows>;
        accent?: Partial<ColorStrength>;
        warning?: Partial<ColorStrength>;
        danger?: Partial<ColorStrength>;
        white?: Partial<Omit<Strength, "faint">>;
        black?: Partial<Omit<Strength, "faint">>;
    }

    interface ColorStrength {
        A800: string;
        A700: string;
        A500: string;
        A400: string;
        A300: string;
    }

    interface FixedColors {
        accent: string;
        warning: string;
        danger: string;
        white: string;
        black: string;
    }

    interface BackgroundType {
        base: string;
        elevated: string;
        elevated2: string;
    }

    interface Strength {
        base: string;
        muted: string;
        faint: string;
    }

    type FillStrength = Strength & {
        basePressed: string;
        faintPressed: string;
    };
}

// Add new tokens to the Palette.
//
// https://mui.com/material-ui/customization/css-theme-variables/usage/#adding-new-theme-tokens

declare module "@mui/material/styles" {
    interface Palette {
        accent: PaletteColor;
        critical: PaletteColor;
        /**
         * MUI as of v6 does not allow customizing the shadows easily. This is
         * due for change: https://github.com/mui/material-ui/issues/44291.
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
        accent?: PaletteColorOptions;
        critical?: PaletteColorOptions;
        boxShadow?: Palette["boxShadow"];
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

export {};
