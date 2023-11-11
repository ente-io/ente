import React from 'react';
import Document, {
    Html,
    Head,
    Main,
    NextScript,
    DocumentProps,
    DocumentContext,
} from 'next/document';

import createEmotionServer from '@emotion/server/create-instance';
import { AppType } from 'next/app';
import createEmotionCache from '@ente/shared/themes/createEmotionCache';
import { EnteAppProps } from '@ente/shared/apps/types';

export interface EnteDocumentProps extends DocumentProps {
    emotionStyleTags: JSX.Element[];
}

export default function EnteDocument({ emotionStyleTags }: EnteDocumentProps) {
    return (
        <Html lang="en">
            <Head>
                <meta
                    name="description"
                    content="ente - end-to-end encrypted cloud with open-source apps"
                />
                <link rel="icon" href="/images/favicon.png" type="image/png" />
                <link rel="icon" type="image/png" href="/images/favicon.png" />
                <meta name="apple-mobile-web-app-capable" content="yes" />
                {emotionStyleTags}
            </Head>
            <body>
                <Main />
                <NextScript />
            </body>
        </Html>
    );
}

// `getInitialProps` belongs to `_document` (instead of `_app`),
// it's compatible with static-site generation (SSG).
EnteDocument.getInitialProps = async (ctx: DocumentContext) => {
    // Resolution order
    //
    // On the server:
    // 1. app.getInitialProps
    // 2. page.getInitialProps
    // 3. document.getInitialProps
    // 4. app.render
    // 5. page.render
    // 6. document.render
    //
    // On the server with error:
    // 1. document.getInitialProps
    // 2. app.render
    // 3. page.render
    // 4. document.render
    //
    // On the client
    // 1. app.getInitialProps
    // 2. page.getInitialProps
    // 3. app.render
    // 4. page.render

    const originalRenderPage = ctx.renderPage;

    // You can consider sharing the same Emotion cache between all the SSR requests to speed up performance.
    // However, be aware that it can have global side effects.
    const cache = createEmotionCache();
    // eslint-disable-next-line @typescript-eslint/unbound-method
    const { extractCriticalToChunks } = createEmotionServer(cache);

    ctx.renderPage = () =>
        originalRenderPage({
            enhanceApp: (
                App: React.ComponentType<
                    React.ComponentProps<AppType> & EnteAppProps
                >
            ) =>
                function EnhanceApp(props) {
                    return <App emotionCache={cache} {...props} />;
                },
        });

    const initialProps = await Document.getInitialProps(ctx);
    // This is important. It prevents Emotion to render invalid HTML.
    // See https://github.com/mui/material-ui/issues/26561#issuecomment-855286153
    const emotionStyles = extractCriticalToChunks(initialProps.html);
    const emotionStyleTags = emotionStyles.styles.map((style) => (
        <style
            data-emotion={`${style.key} ${style.ids.join(' ')}`}
            key={style.key}
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: style.css }}
        />
    ));

    return {
        ...initialProps,
        emotionStyleTags,
    };
};
