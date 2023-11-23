// import { Inter } from 'next/font/google';
import PairedSuccessfullyOverlay from 'components/PairedSuccessfullyOverlay';
import { useEffect, useState } from 'react';
import { syncCollections } from 'services/collectionService';
import { syncFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { downloadFileAsBlob } from 'utils/file';

export default function Slideshow() {
    const [collectionFiles, setCollectionFiles] = useState<EnteFile[]>([]);

    const [currentFile, setCurrentFile] = useState<EnteFile | undefined>(
        undefined
    );

    const [loading, setLoading] = useState(true);

    const init = async () => {
        const collections = await syncCollections();

        // get requested collection id from localStorage
        const requestedCollectionID =
            window.localStorage.getItem('targetCollectionId');

        const files = await syncFiles('normal', collections, () => {});

        if (requestedCollectionID) {
            const collectionFiles = files.filter(
                (file) => file.collectionID === Number(requestedCollectionID)
            );

            setCollectionFiles(collectionFiles);
        }
    };

    useEffect(() => {
        init();
    }, []);

    useEffect(() => {
        // create interval to change slide
        const interval = setInterval(() => {
            // set the currentFile to the next file in the collection for the slideshow
            const currentIndex = collectionFiles.findIndex(
                (file) => file.id === currentFile?.id
            );

            const nextIndex = (currentIndex + 1) % collectionFiles.length;

            const nextFile = collectionFiles[nextIndex];

            setCurrentFile(nextFile);
        }, 5000);

        return () => {
            clearInterval(interval);
        };
    }, [collectionFiles, currentFile]);

    const [renderableFileURL, setRenderableFileURL] = useState<string>('');

    const getRenderableFileURL = async () => {
        const blob = await downloadFileAsBlob(currentFile as EnteFile);

        const url = URL.createObjectURL(blob);

        setRenderableFileURL(url);

        setLoading(false);
    };

    useEffect(() => {
        if (currentFile) {
            console.log(currentFile);
            getRenderableFileURL();
        }
    }, [currentFile]);

    return (
        <>
            <div
                style={{
                    width: '100vw',
                    height: '100vh',
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                }}>
                <img
                    src={renderableFileURL}
                    style={{
                        maxWidth: '100%',
                        maxHeight: '100%',
                    }}
                />
            </div>
            {loading && <PairedSuccessfullyOverlay />}
        </>
    );
}
