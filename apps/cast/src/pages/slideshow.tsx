import { logError } from '@ente/shared/sentry';
import PairedSuccessfullyOverlay from 'components/PairedSuccessfullyOverlay';
import Theatre from 'components/Theatre';
import { FILE_TYPE } from 'constants/file';
import { useRouter } from 'next/router';
import { createContext, useEffect, useState } from 'react';
import {
    getCastCollection,
    getLocalFiles,
    syncPublicFiles,
} from 'services/cast/castService';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { getPreviewableImage, isRawFileFromFileName } from 'utils/file';

export const SlideshowContext = createContext<{
    showNextSlide: () => void;
}>(null);

const renderableFileURLCache = new Map<number, string>();

export default function Slideshow() {
    const [collectionFiles, setCollectionFiles] = useState<EnteFile[]>([]);

    const [currentFile, setCurrentFile] = useState<EnteFile | undefined>(
        undefined
    );
    const [nextFile, setNextFile] = useState<EnteFile | undefined>(undefined);

    const [loading, setLoading] = useState(true);
    const [castToken, setCastToken] = useState<string>('');
    const [castCollection, setCastCollection] = useState<
        Collection | undefined
    >(undefined);

    const syncCastFiles = async (token: string) => {
        try {
            const castToken = window.localStorage.getItem('castToken');
            const requestedCollectionKey =
                window.localStorage.getItem('collectionKey');
            const collection = await getCastCollection(
                castToken,
                requestedCollectionKey
            );
            if (
                castCollection === undefined ||
                castCollection.updationTime !== collection.updationTime
            ) {
                setCastCollection(collection);
                await syncPublicFiles(token, collection, () => {});
                const files = await getLocalFiles(String(collection.id));
                setCollectionFiles(
                    files.filter((file) => isFileEligibleForCast(file))
                );
            }
        } catch (e) {
            logError(e, 'error during sync');
            router.push('/');
        }
    };

    const init = async () => {
        try {
            const castToken = window.localStorage.getItem('castToken');
            setCastToken(castToken);
        } catch (e) {
            logError(e, 'error during sync');
            router.push('/');
        }
    };

    useEffect(() => {
        if (castToken) {
            const intervalId = setInterval(() => {
                syncCastFiles(castToken);
            }, 5000);

            return () => clearInterval(intervalId);
        }
    }, [castToken]);

    const isFileEligibleForCast = (file: EnteFile) => {
        const fileType = file.metadata.fileType;
        if (fileType !== FILE_TYPE.IMAGE && fileType !== FILE_TYPE.LIVE_PHOTO) {
            return false;
        }

        const fileSizeLimit = 100 * 1024 * 1024;

        if (file.info.fileSize > fileSizeLimit) {
            return false;
        }

        const name = file.metadata.title;

        if (fileType === FILE_TYPE.IMAGE) {
            if (isRawFileFromFileName(name)) {
                return false;
            }
        }

        return true;
    };

    const router = useRouter();

    useEffect(() => {
        init();
    }, []);

    useEffect(() => {
        if (collectionFiles.length < 1) return;
        showNextSlide();
    }, [collectionFiles]);

    const showNextSlide = () => {
        const currentIndex = collectionFiles.findIndex(
            (file) => file.id === currentFile?.id
        );

        const nextIndex = (currentIndex + 1) % collectionFiles.length;
        const nextNextIndex = (nextIndex + 1) % collectionFiles.length;

        const nextFile = collectionFiles[nextIndex];
        const nextNextFile = collectionFiles[nextNextIndex];

        setCurrentFile(nextFile);
        setNextFile(nextNextFile);
    };

    const [renderableFileURL, setRenderableFileURL] = useState<string>('');

    const getRenderableFileURL = async () => {
        if (!currentFile) return;

        const cacheValue = renderableFileURLCache.get(currentFile.id);
        if (cacheValue) {
            setRenderableFileURL(cacheValue);
            setLoading(false);
            return;
        }

        try {
            const blob = await getPreviewableImage(
                currentFile as EnteFile,
                castToken
            );

            const url = URL.createObjectURL(blob);

            renderableFileURLCache.set(currentFile?.id, url);

            setRenderableFileURL(url);
        } catch (e) {
            return;
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (currentFile) {
            getRenderableFileURL();
        }
    }, [currentFile]);

    return (
        <>
            <SlideshowContext.Provider value={{ showNextSlide }}>
                <Theatre
                    file1={{
                        fileName: currentFile?.metadata.title,
                        fileURL: renderableFileURL,
                        type: currentFile?.metadata.fileType,
                    }}
                    file2={{
                        fileName: nextFile?.metadata.title,
                        fileURL: renderableFileURL,
                        type: nextFile?.metadata.fileType,
                    }}
                />
            </SlideshowContext.Provider>
            {loading && <PairedSuccessfullyOverlay />}
        </>
    );
}
