import { APPS } from "@ente/shared/apps/constants";
import { createTheme } from "@mui/material";
import { getColors } from "./colors";
import { getComponents } from "./components";
import { THEME_COLOR } from "./constants";
import { getPallette } from "./palette";
import { typography } from "./typography";

export const getTheme = (themeColor: THEME_COLOR, appName: APPS) => {
    const colors = getColors(themeColor, appName);
    const palette = getPallette(themeColor, colors);
    const components = getComponents(colors, typography);
    const theme = createTheme({
        colors,
        palette,
        typography,
        components,
        shape: {
            borderRadius: 8,
        },
        transitions: {
            duration: { leavingScreen: 300 },
        },
    });
    return theme;
};
