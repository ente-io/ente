import { AlbumsAppProviders } from "@/app/providers/AlbumsAppProviders";
import "@fontsource-variable/inter";
import type { AppProps } from "next/app";

import "@/app/styles/global.css";
import "photoswipe/dist/photoswipe.css";
// Keep our PhotoSwipe overrides after the library CSS so the reduced z-index
// wins over PhotoSwipe's default 10k layer.
import "@/app/styles/photoswipe.css";

type AlbumsAppProps = AppProps<Record<string, unknown>>;

const App: React.FC<AlbumsAppProps> = ({ Component, pageProps }) => {
    return (
        <AlbumsAppProviders>
            <Component {...pageProps} />
        </AlbumsAppProviders>
    );
};

export default App;
