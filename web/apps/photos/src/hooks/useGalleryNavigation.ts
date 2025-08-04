import { useCallback, useRef } from 'react';
import { useRouter } from 'next/router';
import { PseudoCollectionID } from 'ente-new/photos/services/collection-summary';
import type { SearchOption } from 'ente-new/photos/services/search/types';

interface UseGalleryNavigationProps {
    dispatch: (action: { type: string; [key: string]: unknown }) => void;
    barMode: string;
    activeCollectionID: number | undefined;
}

/**
 * Custom hook for managing gallery navigation and view changes
 */
export const useGalleryNavigation = ({
    dispatch,
    barMode,
    activeCollectionID,
}: UseGalleryNavigationProps) => {
    const router = useRouter();
    
    /**
     * Grace period tracking for hidden section authentication
     */
    const lastAuthenticationForHiddenTimestamp = useRef<number>(0);

    /**
     * Handle collection summary selection with optional authentication
     */
    const showCollectionSummary = useCallback(
        async (
            collectionSummaryID: number | undefined,
            isHiddenCollectionSummary: boolean | undefined,
            authenticateUser?: () => Promise<void>,
        ) => {
            const lastAuthAt = lastAuthenticationForHiddenTimestamp.current;
            if (
                isHiddenCollectionSummary &&
                barMode !== "hidden-albums" &&
                Date.now() - lastAuthAt > 5 * 60 * 1e3 /* 5 minutes */ &&
                authenticateUser
            ) {
                await authenticateUser();
                lastAuthenticationForHiddenTimestamp.current = Date.now();
            }
            
            // Trigger a pull of the latest data when opening trash
            if (collectionSummaryID === PseudoCollectionID.trash) {
                // This should trigger a remote files pull
                // Will be handled by the calling component
            }

            dispatch({ type: "showCollectionSummary", collectionSummaryID });
        },
        [dispatch, barMode],
    );

    /**
     * Handle search option selection
     */
    const handleSelectSearchOption = useCallback(
        (searchOption: SearchOption | undefined) => {
            if (searchOption) {
                const type = searchOption.suggestion.type;
                if (type === "collection") {
                    dispatch({
                        type: "showCollectionSummary",
                        collectionSummaryID: searchOption.suggestion.collectionID,
                    });
                } else if (type === "person") {
                    dispatch({
                        type: "showPerson",
                        personID: searchOption.suggestion.person.id,
                    });
                } else {
                    dispatch({
                        type: "enterSearchMode",
                        searchSuggestion: searchOption.suggestion,
                    });
                }
            } else {
                dispatch({ type: "exitSearch" });
            }
        },
        [dispatch],
    );

    /**
     * Handle gallery bar mode changes
     */
    const handleChangeBarMode = useCallback(
        (mode: string) => {
            if (mode === "people") {
                dispatch({ type: "showPeople" });
            } else {
                dispatch({ type: "showAlbums" });
            }
        },
        [dispatch],
    );

    /**
     * Handle collection selection
     */
    const handleSelectCollection = useCallback(
        (collectionID: number) =>
            dispatch({
                type: "showCollectionSummary",
                collectionSummaryID: collectionID,
            }),
        [dispatch],
    );

    /**
     * Handle person selection
     */
    const handleSelectPerson = useCallback(
        (personID: string) => dispatch({ type: "showPerson", personID }),
        [dispatch],
    );

    /**
     * Handle entering search mode
     */
    const handleEnterSearchMode = useCallback(
        () => dispatch({ type: "enterSearchMode" }),
        [dispatch],
    );

    /**
     * Handle showing people view
     */
    const handleShowPeople = useCallback(
        () => dispatch({ type: "showPeople" }),
        [dispatch],
    );

    /**
     * Update browser URL based on active collection
     */
    const updateBrowserURL = useCallback(() => {
        if (typeof activeCollectionID === "undefined" || !router.isReady) {
            return;
        }
        
        let collectionURL = "";
        if (activeCollectionID !== PseudoCollectionID.all) {
            collectionURL = `?collection=${activeCollectionID}`;
        }
        const href = `/gallery${collectionURL}`;
        void router.push(href, undefined, { shallow: true });
    }, [activeCollectionID, router]);

    return {
        // Navigation handlers
        showCollectionSummary,
        handleSelectSearchOption,
        handleChangeBarMode,
        handleSelectCollection,
        handleSelectPerson,
        handleEnterSearchMode,
        handleShowPeople,
        updateBrowserURL,
        
        // State
        lastAuthenticationForHiddenTimestamp,
    };
};
