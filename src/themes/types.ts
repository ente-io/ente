import React from 'react';

declare module '@mui/material/styles' {
    interface Palette {
        accent: AccentColor;
        caution: CautionColor;
        danger: DangerColor;
        backdrop: Strength;
        fill: FillStrength;
        stroke: StrokeStrength;
        shadows: Shadows;
        blur: BlurStrength;
        white: Omit<Strength, 'faint'>;
        black: string;
        base: string;
    }

    interface PaletteOptions {
        accent?: Partial<AccentColor>;
        caution?: Partial<CautionColor>;
        danger?: Partial<DangerColor>;
        backdrop?: Partial<Strength>;
        fill?: Partial<FillStrength>;
        stroke?: Partial<StrokeStrength>;
        shadows?: Partial<Shadows>;
        blur?: Partial<BlurStrength>;
        white?: Partial<Omit<Strength, 'faint'>>;
        black?: string;
        base?: string;
    }

    interface TypeText {
        base: string;
        muted: string;
        faint: string;
    }

    interface TypeBackground {
        base: string;
        elevated: string;
        elevated2: string;
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
        danger: true;
    }
}
declare module '@mui/material/Checkbox' {
    interface CheckboxPropsColorOverrides {
        accent: true;
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
    interface AlertPropsColorOverrides {
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
    interface BasePalette {
        accent: AccentColor;
        danger: DangerColor;
        caution: CautionColor;
        blur: BlurStrength;
        white: Omit<Strength, 'faint'>;
        black: string;
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
        y: number;
        blur: number;
        color: string;
    }

    interface AccentColor {
        700: string;
        500: string;
        400: string;
        300: string;
    }
    interface CautionColor {
        500: string;
    }
    interface DangerColor {
        800: string;
        700: string;
        500: string;
        400: string;
    }

    interface BlurStrength {
        base: number;
        muted: number;
        faint: number;
    }
}
export {};
