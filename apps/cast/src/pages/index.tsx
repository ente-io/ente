// import { Inter } from 'next/font/google';
import { useEffect } from 'react';
import { syncCollections } from 'services/collectionService';
import { syncFiles } from 'services/fileService';

// const inter = Inter({ subsets: ['latin'] });

export default function Home() {
    const init = async () => {
        const collections = await syncCollections();

        // get requested collection id from fragment (this is temporary and will be changed during cast)
        const requestedCollectionID = window.location.hash.slice(1);

        const files = await syncFiles('normal', collections, () => {});

        console.log(files);

        if (requestedCollectionID) {
            const collectionFiles = files.filter(
                (file) => file.collectionID === Number(requestedCollectionID)
            );

            console.log('collectionFiles', collectionFiles);
        }
    };

    useEffect(() => {
        init();
    }, []);
    return <></>;
}
