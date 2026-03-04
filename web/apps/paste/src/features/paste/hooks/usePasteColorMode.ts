import { useColorScheme } from "@mui/material/styles";
import { useEffect } from "react";
import type { PasteResolvedMode } from "../theme/pasteThemeTokens";

interface UsePasteColorModeResult {
    resolvedMode: PasteResolvedMode;
}

export const usePasteColorMode = (): UsePasteColorModeResult => {
    const { systemMode, setMode } = useColorScheme();

    useEffect(() => {
        setMode("system");
    }, [setMode]);

    const resolvedMode: PasteResolvedMode = systemMode ?? "dark";

    return {
        resolvedMode,
    };
};
