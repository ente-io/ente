import type { FixedColors, ThemeColorsOptions } from "@mui/material";
import { THEME_COLOR } from "./constants";

export type ColorAccentType = "auth" | "photos";

export const getColors = (
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
