import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
    return (
        <Html
            lang="en"
            style={{
                height: '100%',
                width: '100%',
            }}>
            <Head />
            <body
                style={{
                    height: '100%',
                    width: '100%',
                    margin: 0,
                    backgroundColor: 'black',
                    color: 'white',
                }}>
                <Main />
                <NextScript />
            </body>
        </Html>
    );
}
