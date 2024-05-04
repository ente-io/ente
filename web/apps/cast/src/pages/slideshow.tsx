import log from "@/next/log";
import { PairedSuccessfullyOverlay } from "components/PairedSuccessfullyOverlay";
import { SlideView } from "components/Slide";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { readCastData, renderableImageURLs } from "services/cast";

export default function Slideshow() {
    const [loading, setLoading] = useState(true);
    const [imageURL, setImageURL] = useState<string | undefined>();
    const [nextImageURL, setNextImageURL] = useState<string | undefined>();

    const router = useRouter();

    /** Go back to pairing page */
    const pair = () => router.push("/");

    useEffect(() => {
        let stop = false;

        const loop = async () => {
            try {
                const urlGenerator = renderableImageURLs(readCastData());
                while (!stop) {
                    const { value: urls, done } = await urlGenerator.next();
                    if (done) {
                        log.warn("Empty collection");
                        pair();
                        return;
                    }

                    setImageURL(urls[0]);
                    setNextImageURL(urls[1]);
                    setLoading(false);
                }
            } catch (e) {
                log.error("Failed to prepare generator", e);
                pair();
            }
        };

        void loop();

        return () => {
            stop = true;
        };
    }, []);

    if (loading) return <PairedSuccessfullyOverlay />;

    return <SlideView url={imageURL} nextURL={nextImageURL} />;
}
