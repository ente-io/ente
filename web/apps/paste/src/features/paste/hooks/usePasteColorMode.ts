import { useColorScheme, useTheme } from "@mui/material/styles";
import type { PasteResolvedMode } from "../theme/pasteThemeTokens";

type PasteModePreference = "system" | "light" | "dark";

interface UsePasteColorModeResult {
    mode: PasteModePreference;
    resolvedMode: PasteResolvedMode;
    setMode: (mode: PasteModePreference) => void;
}

export const usePasteColorMode = (): UsePasteColorModeResult => {
    const { mode, systemMode, setMode } = useColorScheme();
    const theme = useTheme();

    const normalizedMode: PasteModePreference = mode ?? "system";
    const themeMode: PasteResolvedMode =
        theme.palette.mode === "light" ? "light" : "dark";
    const resolvedMode: PasteResolvedMode =
        normalizedMode === "system" ? (systemMode ?? themeMode) : normalizedMode;

    return {
        mode: normalizedMode,
        resolvedMode,
        setMode: (nextMode) => {
            setMode(nextMode);
        },
    };
};
