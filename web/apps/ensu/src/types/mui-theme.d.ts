import type { CSSProperties } from "react";

// Ensu-specific typography variant augmentations.
// These extend the shared MUI theme types with variants only used by ensu.

declare module "@mui/material/styles" {
    interface TypographyVariants {
        message: CSSProperties;
        code: CSSProperties;
    }

    interface TypographyVariantsOptions {
        message?: CSSProperties;
        code?: CSSProperties;
    }
}

declare module "@mui/material/Typography" {
    interface TypographyPropsVariantOverrides {
        message: true;
        code: true;
    }
}
