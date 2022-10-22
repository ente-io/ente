import constants from 'utils/strings/constants';
import PhotoFrame from 'components/PhotoFrame';
import { ALL_SECTION } from 'constants/collection';
import { AppContext } from 'pages/_app';
import React, { createContext, useContext, useEffect, useState } from 'react';
import {
    getDuplicateFiles,
    clubDuplicatesByTime,
} from 'services/deduplicationService';
import { syncFiles, trashFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { SelectedState } from 'types/gallery';

import { ServerErrorCodes } from 'utils/error';
import { getSelectedFiles } from 'utils/file';
import {
    DeduplicateContextType,
    DefaultDeduplicateContext,
} from 'types/deduplicate';
import Router from 'next/router';
import DeduplicateOptions from 'components/pages/dedupe/SelectedFileOptions';
import { PAGES } from 'constants/pages';
import router from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { styled } from '@mui/material';
import { syncCollections } from 'services/collectionService';

export const DeduplicateContext = createContext<DeduplicateContextType>(
    DefaultDeduplicateContext
);
export const Info = styled('div')`
    padding: 24px;
    font-size: 18px;
`;

export default function Deduplicate() {
    const {
        setDialogMessage,
        startLoading,
        finishLoading,
        showNavBar,
        setRedirectURL,
    } = useContext(AppContext);
    const [duplicateFiles, setDuplicateFiles] = useState<EnteFile[]>(null);
    const [clubSameTimeFilesOnly, setClubSameTimeFilesOnly] = useState(false);
    const [fileSizeMap, setFileSizeMap] = useState(new Map<number, number>());
    const [collectionNameMap, setCollectionNameMap] = useState(
        new Map<number, string>()
    );
    const [selected, setSelected] = useState<SelectedState>({
        count: 0,
        collectionID: 0,
    });
    const closeDeduplication = function () {
        Router.push(PAGES.GALLERY);
    };
    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            setRedirectURL(router.asPath);
            router.push(PAGES.ROOT);
            return;
        }
        showNavBar(true);
        setDuplicateFiles([]);
    }, []);

    useEffect(() => {
        syncWithRemote();
    }, [clubSameTimeFilesOnly]);

    const syncWithRemote = async () => {
        startLoading();
        const collections = await syncCollections();
        const collectionNameMap = new Map<number, string>();
        for (const collection of collections) {
            collectionNameMap.set(collection.id, collection.name);
        }
        setCollectionNameMap(collectionNameMap);
        const files = await syncFiles(collections, () => null);
        let duplicates = await getDuplicateFiles(files, collectionNameMap);
        if (clubSameTimeFilesOnly) {
            duplicates = clubDuplicatesByTime(duplicates);
        }
        const currFileSizeMap = new Map<number, number>();
        let allDuplicateFiles: EnteFile[] = [];
        let toSelectFileIDs: number[] = [];
        let count = 0;
        for (const dupe of duplicates) {
            allDuplicateFiles = [...allDuplicateFiles, ...dupe.files];
            // select all except first file
            toSelectFileIDs = [
                ...toSelectFileIDs,
                ...dupe.files.slice(1).map((f) => f.id),
            ];
            count += dupe.files.length - 1;

            for (const file of dupe.files) {
                currFileSizeMap.set(file.id, dupe.size);
            }
        }
        setDuplicateFiles(allDuplicateFiles);
        setFileSizeMap(currFileSizeMap);
        const selectedFiles = {
            count: count,
            collectionID: ALL_SECTION,
        };
        for (const fileID of toSelectFileIDs) {
            selectedFiles[fileID] = true;
        }
        setSelected(selectedFiles);
        finishLoading();
    };

    const deleteFileHelper = async () => {
        try {
            startLoading();
            const selectedFiles = getSelectedFiles(selected, duplicateFiles);
            await trashFiles(selectedFiles);
        } catch (e) {
            switch (e.status?.toString()) {
                case ServerErrorCodes.FORBIDDEN:
                    setDialogMessage({
                        title: constants.ERROR,

                        close: { variant: 'danger' },
                        content: constants.NOT_FILE_OWNER,
                    });
            }
            setDialogMessage({
                title: constants.ERROR,

                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote();
            finishLoading();
        }
    };

    const clearSelection = function () {
        setSelected({ count: 0, collectionID: 0 });
    };

    if (!duplicateFiles) {
        return <></>;
    }

    return (
        <DeduplicateContext.Provider
            value={{
                ...DefaultDeduplicateContext,
                collectionNameMap,
                clubSameTimeFilesOnly,
                setClubSameTimeFilesOnly,
                fileSizeMap,
                isOnDeduplicatePage: true,
            }}>
            {duplicateFiles.length > 0 && (
                <Info>
                    {constants.DEDUPLICATION_LOGIC_MESSAGE(
                        clubSameTimeFilesOnly
                    )}
                </Info>
            )}
            <PhotoFrame
                files={duplicateFiles}
                setFiles={setDuplicateFiles}
                syncWithRemote={syncWithRemote}
                setSelected={setSelected}
                selected={selected}
                activeCollection={ALL_SECTION}
                isDeduplicating
            />
            <DeduplicateOptions
                deleteFileHelper={deleteFileHelper}
                count={selected.count}
                close={closeDeduplication}
                clearSelection={clearSelection}
            />
        </DeduplicateContext.Provider>
    );
}
