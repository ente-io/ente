import { Head, Html, Main, NextScript } from "next/document";

export default function EnteDocument() {
    return (
        <Html lang="en">
            <Head>
                <meta
                    name="description"
                    content="Ente - end-to-end encrypted cloud with open-source apps"
                />
                <link rel="icon" href="/images/favicon.png" type="image/png" />
            </Head>
            <body>
                <Main />
                <NextScript />
            </body>
        </Html>
    );
}
