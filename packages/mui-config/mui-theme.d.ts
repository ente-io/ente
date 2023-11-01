import { PaletteColor, PaletteColorOptions } from '@mui/material';
import React from 'react';

declare module '@mui/material/styles' {
    interface Theme {
        colors: ThemeColors;
    }

    interface ThemeOptions {
        colors?: ThemeColorsOptions;
    }

    interface Palette {
        accent: PaletteColor;
        critical: PaletteColor;
    }

    interface PaletteOptions {
        accent?: PaletteColorOptions;
        critical?: PaletteColorOptions;
    }

    interface TypeText {
        base: string;
        muted: string;
        faint: string;
    }

    interface TypographyVariants {
        large: React.CSSProperties;
        body: React.CSSProperties;
        small: React.CSSProperties;
        mini: React.CSSProperties;
        tiny: React.CSSProperties;
    }
    interface TypographyVariantsOptions {
        large?: React.CSSProperties;
        body?: React.CSSProperties;
        small?: React.CSSProperties;
        mini?: React.CSSProperties;
        tiny?: React.CSSProperties;
    }
}

declare module '@mui/material/Typography' {
    interface TypographyPropsVariantOverrides {
        large: true;
        body: true;
        small: true;
        mini: true;
        tiny: true;
        h4: false;
        h5: false;
        h6: false;
        subtitle1: false;
        subtitle2: false;
        body1: false;
        body2: false;
        caption: false;
        button: false;
        overline: false;
    }
}

declare module '@mui/material/Button' {
    interface ButtonPropsColorOverrides {
        accent: true;
        critical: true;
        error: false;
        success: false;
        info: false;
        warning: false;
    }
}
declare module '@mui/material/Checkbox' {
    interface CheckboxPropsColorOverrides {
        accent: true;
        critical: true;
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

declare module '@mui/material/CircularProgress' {
    interface CircularProgressPropsColorOverrides {
        accent: true;
    }
}

// =================================================
// Custom Interfaces
// =================================================

declare module '@mui/material/styles' {
    interface ThemeColors {
        background: BackgroundType;
        backdrop: Strength;
        text: Strength;
        fill: FillStrength;
        stroke: StrokeStrength;
        shadows: Shadows;
        accent: ColorStrength;
        warning: ColorStrength;
        danger: ColorStrength;
        blur: BlurStrength;
        white: Omit<Strength, 'faint'>;
        black: Omit<Strength, 'faint'>;
        avatarColors: AvatarColors;
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
        blur?: Partial<BlurStrength>;
        white?: Partial<Omit<Strength, 'faint'>>;
        black?: Partial<Omit<Strength, 'faint'>>;
        avatarColors?: Partial<AvatarColors>;
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
        blur: number;
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

    type FillStrength = Strength & StrengthFillPressed & StrengthFillStrong;

    interface StrengthFillPressed {
        basePressed: string;
        faintPressed: string;
    }

    interface StrengthFillStrong {
        strong: string;
    }

    type StrokeStrength = Strength & StrengthExtras;

    interface StrengthExtras {
        fainter: string;
    }

    interface Shadows {
        float: Shadow[];
        menu: Shadow[];
        button: Shadow[];
    }

    interface Shadow {
        x: number;
        y: number;
        blur: number;
        color: string;
    }

    interface BlurStrength {
        base: number;
        muted: number;
        faint: number;
    }

    type AvatarColors = Array<string>;
}
export {};
