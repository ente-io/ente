import { ALL_SECTION } from 'constants/collection';
import PhotoFrame from 'components/PhotoFrame';
import React, { useEffect, useState } from 'react';
import { getSharedCollectionFiles } from 'services/sharedCollectionService';

export default function sharedAlbum() {
    const [token, setToken] = useState(null);
    const [collectionKey, setCollectionKey] = useState(null);
    const [files, setFiles] = useState([]);
    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const token = urlParams.get('accessToken');
        const collectionKey = decodeURIComponent(
            urlParams.get('collectionKey')
        );
        setToken(token);
        setCollectionKey(collectionKey);
        syncWithRemote(token, collectionKey);
    }, []);

    const syncWithRemote = async (t?: string, c?: string) => {
        const files = await getSharedCollectionFiles(
            t ?? token,
            c ?? collectionKey,
            setFiles
        );
        setFiles(files);
    };

    return (
        <PhotoFrame
            files={files}
            setFiles={setFiles}
            syncWithRemote={syncWithRemote}
            favItemIds={null}
            setSelected={() => null}
            selected={{ count: 0, collectionID: null }}
            isFirstLoad={false}
            openFileUploader={() => null}
            loadingBar={null}
            isInSearchMode={false}
            search={{}}
            setSearchStats={() => null}
            deleted={[]}
            activeCollection={ALL_SECTION}
            isSharedCollection={true}
        />
    );
}
