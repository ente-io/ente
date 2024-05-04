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
        let urlGenerator: AsyncGenerator<[string, string], void>;
        try {
            urlGenerator = renderableImageURLs(readCastData());
        } catch (e) {
            log.error("Failed to prepare generator", e);
            pair();
        }

        advance(urlGenerator);

        const interval = window.setInterval(() => {
            advance(urlGenerator);
        }, 10000);

        return () => clearInterval(interval);
    }, []);

    const advance = async (
        urlGenerator: AsyncGenerator<[string, string], void>,
    ) => {
        try {
            const { value: urls, done } = await urlGenerator.next();
            if (done) {
                log.warn("Empty collection");
                pair();
                return;
            }

            setImageURL(urls[0]);
            setNextImageURL(urls[1]);
            setLoading(false);
        } catch (e) {
            log.error("Failed to generate image URL", e);
            pair();
        }
    };

    /*
    const showNextSlide = async () => {
        try {
            console.log("showNextSlide");
            const currentIndex = collectionFiles.findIndex(
                (file) => file.id === currentFileId,
            );

            console.log(
                "showNextSlide-index",
                currentIndex,
                collectionFiles.length,
            );

            const nextIndex = (currentIndex + 1) % collectionFiles.length;
            const nextNextIndex = (nextIndex + 1) % collectionFiles.length;

            console.log(
                "showNextSlide-nextIndex and nextNextIndex",
                nextIndex,
                nextNextIndex,
            );

            const nextFile = collectionFiles[nextIndex];
            const nextNextFile = collectionFiles[nextNextIndex];

            let nextURL: string;
            try {
                nextURL = await createRenderableURL(nextFile, castToken);
            } catch (e) {
                console.log("error in nextUrl", e);
                return;
            }

            let nextNextURL: string;
            try {
                nextNextURL = await createRenderableURL(
                    nextNextFile,
                    castToken,
                );
            } catch (e) {
                console.log("error in nextNextURL", e);
                return;
            }

            setLoading(false);
            setCurrentFileId(nextFile.id);
            // TODO: These might be the same in case the album has < 3 files
            // so commenting this out for now.
            // if (currentFileURL) URL.revokeObjectURL(currentFileURL);
            setCurrentFileURL(nextURL);
            // if (nextFileURL) URL.revokeObjectURL(nextFileURL);
            setNextFileURL(nextNextURL);
        } catch (e) {
            console.log("error in showNextSlide", e);
        }
    };
    */

    if (loading) return <PairedSuccessfullyOverlay />;

    return <SlideView url={imageURL} nextURL={nextImageURL} />;
}
