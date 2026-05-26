import NextDocument, {
    Head,
    Html,
    Main,
    NextScript,
    type DocumentContext,
    type DocumentInitialProps,
} from "next/document";
import { isValidElement, type ReactElement } from "react";

interface MetaProps {
    name?: unknown;
}

const isViewportMeta = (element: ReactElement | null) =>
    isValidElement<MetaProps>(element) &&
    element.type === "meta" &&
    element.props.name === "viewport";

export default class Document extends NextDocument {
    static override async getInitialProps(
        ctx: DocumentContext,
    ): Promise<DocumentInitialProps> {
        const initialProps = await NextDocument.getInitialProps(ctx);

        return {
            ...initialProps,
            head: initialProps.head?.filter(
                (element) => !isViewportMeta(element),
            ),
        };
    }

    override render() {
        return (
            <Html lang="en">
                <Head>
                    <title>Ente Paste</title>
                    <link
                        rel="icon"
                        href="/images/favicon.png"
                        type="image/png"
                    />
                    <link
                        rel="preload"
                        href="/fonts/gochi-hand-latin.woff2"
                        as="font"
                        type="font/woff2"
                        crossOrigin="anonymous"
                    />
                    <meta
                        name="description"
                        content="Share sensitive text with one-time, end-to-end encrypted links that auto-expire after 24 hours."
                    />
                    <meta
                        property="og:image"
                        content="https://paste.ente.com/images/metaimage.png"
                    />
                    <meta
                        name="twitter:image"
                        content="https://paste.ente.com/images/metaimage.png"
                    />
                    <meta
                        name="viewport"
                        content="width=device-width, initial-scale=1"
                    />
                    <meta
                        name="referrer"
                        content="strict-origin-when-cross-origin"
                    />
                </Head>
                <body>
                    <Main />
                    <NextScript />
                </body>
            </Html>
        );
    }
}
