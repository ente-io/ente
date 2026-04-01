import { AlbumsAppProviders } from "@/app/providers/AlbumsAppProviders";
import "@fontsource-variable/inter";
import type { AppProps } from "next/app";

import "@/app/styles/global.css";
import "@/app/styles/photoswipe.css";
import "photoswipe/dist/photoswipe.css";

type AlbumsAppProps = AppProps<Record<string, unknown>>;

const App: React.FC<AlbumsAppProps> = ({ Component, pageProps }) => {
    return (
        <AlbumsAppProviders>
            <Component {...pageProps} />
        </AlbumsAppProviders>
    );
};

export default App;
