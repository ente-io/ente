import PairedSuccessfullyOverlay from 'components/PairedSuccessfullyOverlay';
import Theatre from 'components/Theatre';
import { FILE_TYPE } from 'constants/file';
import { useRouter } from 'next/router';
import { createContext, useEffect, useState } from 'react';
import { getCollection } from 'services/collectionService';
import { syncFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { downloadFileAsBlob, isRawFileFromFileName } from 'utils/file';
import { useCastReceiver } from '@ente/shared/hooks/useCastReceiver';

export const SlideshowContext = createContext<{
    showNextSlide: () => void;
}>(null);

export default function Slideshow() {
    const [collectionFiles, setCollectionFiles] = useState<EnteFile[]>([]);

    const [currentFile, setCurrentFile] = useState<EnteFile | undefined>(
        undefined
    );
    const [nextFile, setNextFile] = useState<EnteFile | undefined>(undefined);

    const [loading, setLoading] = useState(true);

    const [renderableFileURLCache, setRenderableFileURLCache] = useState<
        Record<string, string>
    >({});

    const { cast } = useCastReceiver();

    const init = async () => {
        try {
            const options = new cast.framework.CastReceiverOptions();

            options.disableIdleTimeout = true;

            cast.framework.CastReceiverContext.getInstance().start(options);

            // get requested collection id from localStorage
            const requestedCollectionID =
                window.localStorage.getItem('targetCollectionId');

            const collection = await getCollection(
                Number(requestedCollectionID)
            );

            const files = await syncFiles('normal', [collection], () => {});

            if (requestedCollectionID) {
                setCollectionFiles(
                    files.filter((file) => isFileEligibleForCast(file))
                );
            }
        } catch {
            router.push('/');
        }
    };

    const isFileEligibleForCast = (file: EnteFile) => {
        const fileType = file.metadata.fileType;
        if (
            fileType !== FILE_TYPE.IMAGE
            // && fileType !== FILE_TYPE.VIDEO
        ) {
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
        if (!cast) return;
        init();
    }, [cast]);

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

        if (renderableFileURLCache[currentFile.id]) {
            setRenderableFileURL(renderableFileURLCache[currentFile.id]);
            setLoading(false);
            return;
        }

        try {
            const blob = await downloadFileAsBlob(currentFile as EnteFile);

            const url = URL.createObjectURL(blob);

            setRenderableFileURLCache({
                ...renderableFileURLCache,
                [currentFile?.id]: url,
            });

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
