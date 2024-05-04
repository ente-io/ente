import log from "@/next/log";
import { PairedSuccessfullyOverlay } from "components/PairedSuccessfullyOverlay";
import { SlideView } from "components/Slide";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { readCastData, renderableURLs } from "services/cast";

export default function Slideshow() {
    const [loading, setLoading] = useState(true);
    const [castToken, setCastToken] = useState<string>("");
    // const [castCollection, setCastCollection] = useState<
    // Collection | undefined
    // >();
    // const [collectionFiles, setCollectionFiles] = useState<EnteFile[]>([]);
    // const [currentFileId, setCurrentFileId] = useState<number | undefined>();
    const [currentFileURL, setCurrentFileURL] = useState<string | undefined>();
    const [nextFileURL, setNextFileURL] = useState<string | undefined>();
    const [urlGenerator, setURLGenerator] = useState<
        AsyncGenerator | undefined
    >();
    // const [canCast, setCanCast] = useState(false);

    const router = useRouter();

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const syncCastFiles = async (token: string) => {
        try {
            setURLGenerator(renderableURLs(readCastData()));
            // setCanCast(true);
            setLoading(false);
        } catch (e) {
            log.error("Failed to prepare URL generator", e);
            // Go back to pairing page
            router.push("/");
        }
    };

    const advance = async () => {
        console.log("in advance");
        if (!urlGenerator) throw new Error("Unexpected state");
        const { value: urls, done } = await urlGenerator.next();
        if (done) {
            log.warn("Empty collection");
            // Go back to pairing page
            router.push("/");
            return;
        }
        setCurrentFileURL(urls[0]);
        setNextFileURL(urls[1]);
    };

    /*
    const syncCastFiles0 = async (token: string) => {
        try {
            const { castToken, collectionKey } = readCastData();
            const collection = await getCastCollection(
                collectionKey,
                castToken,
            );
            if (
                castCollection === undefined ||
                castCollection.updationTime !== collection.updationTime
            ) {
                setCastCollection(collection);
                await syncPublicFiles(token, collection, () => {});
                const files = await getLocalFiles(String(collection.id));
                setCollectionFiles(
                    files.filter((file) => isFileEligibleForCast(file)),
                );
            }
        } catch (e) {
            log.error("error during sync", e);
            // go back to preview page
            router.push("/");
        }
    };
    */

    useEffect(() => {
        if (castToken) {
            const intervalId = setInterval(() => {
                syncCastFiles(castToken);
            }, 10000);
            syncCastFiles(castToken);

            return () => clearInterval(intervalId);
        }
    }, [castToken]);

    useEffect(() => {
        try {
            const castToken = window.localStorage.getItem("castToken");
            // Wait 2 seconds to ensure the green tick and the confirmation
            // message remains visible for at least 2 seconds before we start
            // the slideshow.
            const timeoutId = setTimeout(() => {
                setCastToken(castToken);
            }, 2000);

            return () => clearTimeout(timeoutId);
        } catch (e) {
            log.error("error during sync", e);
            router.push("/");
        }
    }, []);

    /*
    useEffect(() => {
        if (collectionFiles.length < 1) return;
        showNextSlide();
    }, [collectionFiles]);

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

    useEffect(() => {
        if (loading) return;

        console.log("showing slide");
        const timeoutId = window.setTimeout(() => {
            console.log("showing next slide  timer");
            // showNextSlide();
            advance();
        }, 10000);

        return () => {
            if (timeoutId) clearTimeout(timeoutId);
        };
    }, [loading]);

    console.log({ a: "render", loading, currentFileURL, nextFileURL });

    if (loading || !currentFileURL || !nextFileURL)
        return <PairedSuccessfullyOverlay />;

    return <SlideView url={currentFileURL} nextURL={nextFileURL} />;
}
