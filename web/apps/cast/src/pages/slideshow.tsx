import { FILE_TYPE } from "@/media/file";
import log from "@/next/log";
import PairedSuccessfullyOverlay from "components/PairedSuccessfullyOverlay";
import { PhotoAuditorium } from "components/PhotoAuditorium";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import {
    getCastCollection,
    getLocalFiles,
    syncPublicFiles,
} from "services/cast/castService";
import { Collection } from "types/collection";
import { EnteFile } from "types/file";
import { getPreviewableImage, isRawFileFromFileName } from "utils/file";

const renderableFileURLCache = new Map<number, string>();

export default function Slideshow() {
    const [loading, setLoading] = useState(true);
    const [castToken, setCastToken] = useState<string>("");
    const [castCollection, setCastCollection] = useState<
        Collection | undefined
    >();
    const [collectionFiles, setCollectionFiles] = useState<EnteFile[]>([]);
    const [currentFileId, setCurrentFileId] = useState<number | undefined>();
    const [currentFileURL, setCurrentFileURL] = useState<string | undefined>();
    const [nextFileURL, setNextFileURL] = useState<string | undefined>();

    const router = useRouter();

    const syncCastFiles = async (token: string) => {
        try {
            const castToken = window.localStorage.getItem("castToken");
            const requestedCollectionKey =
                window.localStorage.getItem("collectionKey");
            const collection = await getCastCollection(
                castToken,
                requestedCollectionKey,
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
            router.push("/");
        }
    };

    useEffect(() => {
        if (castToken) {
            const intervalId = setInterval(() => {
                syncCastFiles(castToken);
            }, 10000);
            syncCastFiles(castToken);

            return () => clearInterval(intervalId);
        }
    }, [castToken]);

    const isFileEligibleForCast = (file: EnteFile) => {
        const fileType = file.metadata.fileType;
        if (fileType !== FILE_TYPE.IMAGE && fileType !== FILE_TYPE.LIVE_PHOTO)
            return false;

        if (file.info.fileSize > 100 * 1024 * 1024) return false;

        if (isRawFileFromFileName(file.metadata.title)) return false;

        return true;
    };

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

    useEffect(() => {
        if (collectionFiles.length < 1) return;
        showNextSlide();
    }, [collectionFiles]);

    const showNextSlide = async () => {
        const currentIndex = collectionFiles.findIndex(
            (file) => file.id === currentFileId,
        );

        const nextIndex = (currentIndex + 1) % collectionFiles.length;
        const nextNextIndex = (nextIndex + 1) % collectionFiles.length;

        const nextFile = collectionFiles[nextIndex];
        const nextNextFile = collectionFiles[nextNextIndex];

        let nextURL = renderableFileURLCache.get(nextFile.id);
        let nextNextURL = renderableFileURLCache.get(nextNextFile.id);

        if (!nextURL) {
            try {
                const blob = await getPreviewableImage(nextFile, castToken);
                const url = URL.createObjectURL(blob);
                renderableFileURLCache.set(nextFile.id, url);
                nextURL = url;
            } catch (e) {
                return;
            }
        }

        if (!nextNextURL) {
            try {
                const blob = await getPreviewableImage(nextNextFile, castToken);
                const url = URL.createObjectURL(blob);
                renderableFileURLCache.set(nextNextFile.id, url);
                nextNextURL = url;
            } catch (e) {
                return;
            }
        }

        setLoading(false);
        setCurrentFileId(nextFile.id);
        setCurrentFileURL(nextURL);
        setNextFileURL(nextNextURL);
    };

    if (loading) return <PairedSuccessfullyOverlay />;

    return (
        <PhotoAuditorium
            url={currentFileURL}
            nextSlideUrl={nextFileURL}
            showNextSlide={showNextSlide}
        />
    );
}
