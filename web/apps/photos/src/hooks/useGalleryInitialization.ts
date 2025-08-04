import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { haveMasterKeyInSession } from 'ente-base/session';
import { savedAuthToken } from 'ente-base/token';
import { stashRedirect } from 'ente-accounts/services/redirect';
import { validateKey } from 'ente-new/photos/components/gallery/helpers';
import { 
    getAndClearIsFirstLogin,
    getAndClearJustSignedUp 
} from 'ente-accounts/services/accounts-db';
import { shouldShowWhatsNew } from 'ente-new/photos/services/changelog';
import { initSettings } from 'ente-new/photos/services/settings';
import { useBaseContext } from 'ente-base/context';

interface UseGalleryInitializationProps {
    onInitializeGallery: () => Promise<void>;
    onShowPlanSelector: () => void;
    onShowWhatsNew: () => void;
}

/**
 * Custom hook for handling gallery initialization and authentication checks
 */
export const useGalleryInitialization = ({
    onInitializeGallery,
    onShowPlanSelector,
    onShowWhatsNew,
}: UseGalleryInitializationProps) => {
    const { logout } = useBaseContext();
    const router = useRouter();
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);

    /**
     * Preload all three variants of a responsive image
     */
    const preloadImage = (imgBasePath: string) => {
        const srcset: string[] = [];
        for (let i = 1; i <= 3; i++) srcset.push(`${imgBasePath}/${i}x.png ${i}x`);
        new Image().srcset = srcset.join(",");
    };

    /**
     * Set up keyboard shortcuts for select all
     */
    const setupSelectAllKeyBoardShortcutHandler = () => {
        // This will be handled by the useSelection hook
        // Keeping this function for compatibility
        return () => {
            // Cleanup function - currently handled by useSelection hook
        };
    };

    useEffect(() => {
        const electron = globalThis.electron;
        let syncIntervalID: ReturnType<typeof setInterval> | undefined;

        void (async () => {
            // Check authentication
            if (!haveMasterKeyInSession() || !(await savedAuthToken())) {
                stashRedirect("/gallery");
                void router.push("/");
                return;
            }

            // Validate credentials
            if (!(await validateKey())) {
                logout();
                return;
            }

            // One-time initialization
            preloadImage("/images/subscription-card-background");
            initSettings();
            setupSelectAllKeyBoardShortcutHandler();

            // Check if this is the user's first login
            setIsFirstLoad(getAndClearIsFirstLogin());

            // Show plan selector for new users
            if (getAndClearJustSignedUp()) {
                onShowPlanSelector();
            }

            // Initialize gallery data
            await onInitializeGallery();

            // Clear first load state
            setIsFirstLoad(false);

            // Start periodic sync
            syncIntervalID = setInterval(
                () => {
                    // This should trigger a silent remote pull
                    // Will be handled by the data management hook
                },
                5 * 60 * 1000 /* 5 minutes */,
            );

            // Handle electron-specific features
            if (electron) {
                electron.onMainWindowFocus(() => {
                    // Trigger silent remote pull on focus
                });
                if (await shouldShowWhatsNew(electron)) {
                    onShowWhatsNew();
                }
            }
        })();

        return () => {
            clearInterval(syncIntervalID);
            if (electron) {
                electron.onMainWindowFocus(undefined);
            }
        };
    }, [router, logout, onInitializeGallery, onShowPlanSelector, onShowWhatsNew]);

    return {
        isFirstLoad,
        blockingLoad,
        setBlockingLoad,
    };
};
