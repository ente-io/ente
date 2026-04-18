import { useEffect, useState } from "react";
import type { PageMode } from "../types";

export const usePasteRoute = () => {
    const [mode, setMode] = useState<PageMode>("create");
    const [accessToken, setAccessToken] = useState<string | null>(null);

    useEffect(() => {
        const cleanPath = window.location.pathname.replace(/^\/+|\/+$/g, "");
        if (!cleanPath) {
            setMode("create");
            return;
        }

        setMode("view");
        setAccessToken(cleanPath.split("/")[0] ?? null);
    }, []);

    return { mode, accessToken };
};
