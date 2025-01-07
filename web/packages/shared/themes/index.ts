import { createTheme } from "@mui/material";
import { getColors, type ColorAccentType } from "./colors";
import { getComponents } from "./components";
import { THEME_COLOR } from "./constants";
import { getPallette } from "./palette";
import { typography } from "./typography";

export const getTheme = (
    themeColor: THEME_COLOR,
    colorAccentType: ColorAccentType,
) => {
    const colors = getColors(themeColor, colorAccentType);
    const palette = getPallette(themeColor, colors);
    const components = getComponents(colors, typography);
    const theme = createTheme({
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
    return theme;
};
