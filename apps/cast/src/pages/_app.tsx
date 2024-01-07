import type { AppProps } from 'next/app';
import { Inter } from '@next/font/google';
import 'styles/global.css';
import { ThemeProvider, CssBaseline } from '@mui/material';
import { getTheme } from '@ente/shared/themes';
import { THEME_COLOR } from '@ente/shared/themes/constants';
import { APPS } from '@ente/shared/apps/constants';

const inter = Inter({ subsets: ['latin'], display: 'swap' });

export default function App({ Component, pageProps }: AppProps) {
    return (
        <ThemeProvider theme={getTheme(THEME_COLOR.DARK, APPS.PHOTOS)}>
            <CssBaseline enableColorScheme />

            <main
                className={inter.className}
                style={{
                    display: 'contents',
                }}>
                <Component {...pageProps} />
            </main>
        </ThemeProvider>
    );
}
