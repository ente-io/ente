import React, { createContext, useState, useEffect } from 'react';
import { ThemeProvider } from '@mui/material/styles';
import { getTheme } from '@ente/shared/themes';
import { useLocalState } from '@ente/shared/hooks/useLocalState';
import { LS_KEYS } from '@ente/shared/storage/localStorage';
import { THEME_COLOR } from '@ente/shared/themes/constants';
import { APPS } from '@ente/shared/apps/constants';
import { CssBaseline, useMediaQuery } from '@mui/material';
import { EnteAppProps } from '@ente/shared/apps/types';
import createEmotionCache from '@ente/shared/themes/createEmotionCache';
import { CacheProvider } from '@emotion/react';
import 'styles/global.css';
import { setupI18n } from '@ente/shared/i18n';
import { Overlay } from '@ente/shared/components/Container';
import EnteSpinner from '@ente/shared/components/EnteSpinner';

export const AppContext = createContext(
    {} as {
        isMobile: boolean;
    }
);

// Client-side cache, shared for the whole session of the user in the browser.
const clientSideEmotionCache = createEmotionCache();

export default function App(props: EnteAppProps) {
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);

    const isMobile = useMediaQuery('(max-width:428px)');

    const {
        Component,
        emotionCache = clientSideEmotionCache,
        pageProps,
    } = props;

    const [themeColor] = useLocalState(LS_KEYS.THEME, THEME_COLOR.DARK);

    useEffect(() => {
        setupI18n().finally(() => setIsI18nReady(true));
    }, []);

    return (
        <CacheProvider value={emotionCache}>
            <ThemeProvider theme={getTheme(themeColor, APPS.PHOTOS)}>
                <CssBaseline enableColorScheme />
                <AppContext.Provider value={{ isMobile }}>
                    {!isI18nReady && (
                        <Overlay
                            sx={(theme) => ({
                                display: 'flex',
                                justifyContent: 'center',
                                alignItems: 'center',
                                zIndex: 2000,
                                backgroundColor: theme.colors.background.base,
                            })}>
                            <EnteSpinner />
                        </Overlay>
                    )}
                    <Component {...pageProps} />
                </AppContext.Provider>
            </ThemeProvider>
        </CacheProvider>
    );
}
