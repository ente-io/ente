import { useCallback, useEffect, useRef, useState } from 'react';
import type { SelectedState } from 'utils/file';
import type { EnteFile } from 'ente-media/file';
import { PseudoCollectionID } from 'ente-new/photos/services/collection-summary';

interface UseSelectionProps {
    user: { id: number } | null;
    filteredFiles: EnteFile[];
    activeCollectionID: number | undefined;
    barMode: string;
    activePersonID?: string;
    isAnyModalOpen: boolean;
}

/**
 * Custom hook for managing file selection state and keyboard shortcuts
 */
export const useSelection = ({
    user,
    filteredFiles,
    activeCollectionID,
    barMode,
    activePersonID,
    isAnyModalOpen,
}: UseSelectionProps) => {
    const [selected, setSelected] = useState<SelectedState>({
        ownCount: 0,
        count: 0,
        collectionID: 0,
        context: { mode: "albums", collectionID: PseudoCollectionID.all },
    });

    const selectAll = useCallback((e: KeyboardEvent) => {
        // Don't intercept Ctrl/Cmd + a if the user is typing in a text field
        if (
            e.target instanceof HTMLInputElement ||
            e.target instanceof HTMLTextAreaElement
        ) {
            return;
        }

        e.preventDefault();

        // Don't select all if conditions aren't met
        if (
            !user ||
            !filteredFiles.length ||
            isAnyModalOpen
        ) {
            return;
        }

        // Create a selection with everything based on the current context
        const newSelected = {
            ownCount: 0,
            count: 0,
            collectionID: activeCollectionID,
            context:
                barMode === "people" && activePersonID
                    ? { mode: "people" as const, personID: activePersonID }
                    : {
                          mode: barMode as "albums" | "hidden-albums",
                          collectionID: activeCollectionID!,
                      },
        };

        filteredFiles.forEach((item) => {
            if (item.ownerID === user.id) {
                newSelected.ownCount++;
            }
            newSelected.count++;
            // @ts-expect-error Selection code needs type fixing
            newSelected[item.id] = true;
        });
        setSelected(newSelected);
    }, [user, filteredFiles, activeCollectionID, barMode, activePersonID, isAnyModalOpen]);

    const clearSelection = useCallback(() => {
        if (!selected.count) {
            return;
        }
        setSelected({
            ownCount: 0,
            count: 0,
            collectionID: 0,
            context: undefined,
        });
    }, [selected.count]);

    const keyboardShortcutHandlerRef = useRef({ selectAll, clearSelection });

    useEffect(() => {
        keyboardShortcutHandlerRef.current = { selectAll, clearSelection };
    }, [selectAll, clearSelection]);

    // Set up keyboard shortcuts
    useEffect(() => {
        const handleKeyUp = (e: KeyboardEvent) => {
            switch (e.key) {
                case "Escape":
                    keyboardShortcutHandlerRef.current.clearSelection();
                    break;
                case "a":
                    if (e.ctrlKey || e.metaKey) {
                        keyboardShortcutHandlerRef.current.selectAll(e);
                    }
                    break;
            }
        };
        
        document.addEventListener("keydown", handleKeyUp);
        return () => {
            document.removeEventListener("keydown", handleKeyUp);
        };
    }, []);

    return {
        selected,
        setSelected,
        clearSelection,
        selectAll,
    };
};
