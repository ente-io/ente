import { CustomHead } from "@/next/components/Head";
import { APPS, APP_TITLES } from "@ente/shared/apps/constants";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, ThemeProvider } from "@mui/material";
import type { AppProps } from "next/app";
import "styles/global.css";

export default function App({ Component, pageProps }: AppProps) {
    return (
        <>
            <CustomHead title={APP_TITLES.get(APPS.PHOTOS)} />

            <ThemeProvider theme={getTheme(THEME_COLOR.DARK, APPS.PHOTOS)}>
                <CssBaseline enableColorScheme />

                <main
                    style={{
                        display: "contents",
                    }}
                >
                    <Component {...pageProps} />
                </main>
            </ThemeProvider>
        </>
    );
}
