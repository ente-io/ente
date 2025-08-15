import { useCallback, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { useGalleryReducer } from 'ente-new/photos/components/gallery/reducer';
import { PromiseQueue } from 'ente-utils/promise';
import { usePhotosAppContext } from 'ente-new/photos/types/context';
import { useBaseContext } from 'ente-base/context';
import { 
    savedCollections, 
    savedCollectionFiles, 
    savedTrashItems 
} from 'ente-new/photos/services/photos-fdb';
import { pullFiles, prePullFiles, postPullFiles } from 'ente-new/photos/services/pull';
import { ensureLocalUser } from 'ente-accounts/services/user';
import { savedUserDetailsOrTriggerPull } from 'ente-new/photos/services/user-details';
import { masterKeyFromSession, clearSessionStorage } from 'ente-base/session';
import { isSessionInvalid } from 'ente-accounts/services/session';
import log from 'ente-base/log';
import exportService from 'ente-new/photos/services/export';

export interface RemotePullOpts {
    silent?: boolean;
}

/**
 * Custom hook for managing gallery data fetching and state
 */
export const useGalleryData = () => {
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const { onGenericError } = useBaseContext();
    const router = useRouter();
    
    const [state, dispatch] = useGalleryReducer();
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    
    // Queues for serializing remote operations
    const remoteFilesPullQueue = useRef(new PromiseQueue<void>());
    const remotePullQueue = useRef(new PromiseQueue<void>());

    /**
     * Pull latest collections, collection files and trash items from remote
     */
    const remoteFilesPull = useCallback(
        () =>
            remoteFilesPullQueue.current.add(() =>
                pullFiles({
                    onSetCollections: (collections) =>
                        dispatch({ type: "setCollections", collections }),
                    onSetCollectionFiles: (collectionFiles) =>
                        dispatch({
                            type: "setCollectionFiles",
                            collectionFiles,
                        }),
                    onSetTrashedItems: (trashItems) =>
                        dispatch({ type: "setTrashItems", trashItems }),
                    onDidUpdateCollectionFiles: () =>
                        exportService.onLocalFilesUpdated(),
                }),
            ),
        [],
    );

    /**
     * Perform a full remote pull with error handling
     */
    const remotePull = useCallback(
        async (opts?: RemotePullOpts) =>
            remotePullQueue.current.add(async () => {
                const { silent } = opts ?? {};

                // Pre-flight checks
                if (!navigator.onLine) return;
                if (await isSessionInvalid()) {
                    // Handle session expiry
                    return;
                }
                if (!(await masterKeyFromSession())) {
                    clearSessionStorage();
                    void router.push("/credentials");
                    return;
                }

                try {
                    if (!silent) showLoadingBar();
                    await prePullFiles();
                    await remoteFilesPull();
                    await postPullFiles();
                } catch (e) {
                    log.error("Remote pull failed", e);
                } finally {
                    dispatch({ type: "clearUnsyncedState" });
                    if (!silent) hideLoadingBar();
                }
            }),
        [showLoadingBar, hideLoadingBar, router, remoteFilesPull],
    );

    /**
     * Initialize the gallery on mount
     */
    const initializeGallery = useCallback(async () => {
        try {
            dispatch({ type: "showAll" });
            
            const user = ensureLocalUser();
            const userDetails = await savedUserDetailsOrTriggerPull();
            
            dispatch({
                type: "mount",
                user,
                familyData: userDetails?.familyData,
                collections: await savedCollections(),
                collectionFiles: await savedCollectionFiles(),
                trashItems: await savedTrashItems(),
            });

            await remotePull();
            setIsFirstLoad(false);
        } catch (error) {
            onGenericError(error);
        }
    }, [dispatch, remotePull, onGenericError]);

    return {
        state,
        dispatch,
        isFirstLoad,
        setIsFirstLoad,
        remoteFilesPull,
        remotePull,
        initializeGallery,
    };
};
