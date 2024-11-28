import type { PaletteOptions, ThemeColorsOptions } from "@mui/material";
import { THEME_COLOR } from "./constants";

export const getPallette = (
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

export const getPalletteOptions = (
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
