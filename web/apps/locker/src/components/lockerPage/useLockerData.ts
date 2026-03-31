import { sessionExpiredDialogAttributes } from "ente-accounts-rs/components/utils/dialog";
import { isSavedUserTokenMismatch } from "ente-accounts-rs/services/accounts-db";
import { stashRedirect } from "ente-accounts-rs/services/redirect";
import { masterKeyFromSession } from "ente-accounts-rs/services/session-storage";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import {
    authenticatedRequestHeaders,
    ensureOk,
    isHTTP401Error,
} from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { savedAuthToken } from "ente-base/token";
import { t } from "i18next";
import type { NextRouter } from "next/router";
import { useCallback, useEffect, useRef, useState } from "react";
import {
    isEnteProductionEndpoint,
    LOCKER_FILE_LIMIT_FREE,
    LOCKER_FILE_LIMIT_PAID,
    type LockerUploadLimitState,
} from "services/locker-limits";
import { loadPersistedLockerState, syncLockerState } from "services/remote";
import type { LockerCollection, LockerItem } from "types";

interface LockerBonus {
    type?: string;
}

interface LockerUserDetailsResponse {
    email?: string;
    usage?: number;
    fileCount?: number;
    lockerFamilyUsage?: { familyFileCount?: number };
    familyData?: { members?: unknown[] };
    bonusData?: { storageBonuses?: LockerBonus[] };
    subscription?: {
        storage?: number;
        productID?: string;
        expiryTime?: number;
    };
}

export interface UserDetails extends LockerUploadLimitState {
    email: string;
}

const hasPaidLockerAccess = (json: {
    subscription?: { productID?: string; expiryTime?: number };
    familyData?: { members?: unknown[] };
    bonusData?: { storageBonuses?: LockerBonus[] };
}) => {
    const hasActivePaidSubscription =
        json.subscription?.productID !== "free" &&
        (json.subscription?.expiryTime ?? 0) > Date.now() * 1000;
    const isPartOfFamily = (json.familyData?.members?.length ?? 0) > 0;
    const hasPaidAddon =
        json.bonusData?.storageBonuses?.some(
            (bonus) =>
                bonus.type !== undefined &&
                bonus.type !== "SIGN_UP" &&
                bonus.type !== "REFERRAL",
        ) ?? false;

    return hasActivePaidSubscription || isPartOfFamily || hasPaidAddon;
};

interface UseLockerDataProps {
    router: NextRouter;
    logout: () => void | Promise<void>;
    showMiniDialog: (attributes: MiniDialogAttributes) => void;
}

interface UserDetailsRefreshTrigger {
    collectionsSinceTime: number;
    trashSinceTime: number;
}

interface UploadLimitStateSnapshot {
    isProductionEndpoint: boolean;
    userDetails: UserDetails;
}

interface LoadUserDetailsResult {
    applied: boolean;
    snapshot?: UploadLimitStateSnapshot;
}

export const useLockerData = ({
    router,
    logout,
    showMiniDialog,
}: UseLockerDataProps) => {
    const [collections, setCollections] = useState<LockerCollection[]>([]);
    const [masterKey, setMasterKey] = useState<string | undefined>();
    const [hasFetched, setHasFetched] = useState(false);
    const [initialLoadError, setInitialLoadError] = useState<string | null>(
        null,
    );
    const [isProductionEndpoint, setIsProductionEndpoint] = useState(true);
    const [userDetails, setUserDetails] = useState<UserDetails | undefined>();
    const [trashItems, setTrashItems] = useState<LockerItem[]>([]);
    const [trashLastUpdatedAt, setTrashLastUpdatedAt] = useState(0);

    const mountedRef = useRef(true);
    const latestDataRequestRef = useRef(0);
    const latestUserDetailsRequestRef = useRef(0);
    const lastUserDetailsRefreshKeyRef = useRef<string | undefined>(undefined);
    const pendingUserDetailsRefreshRef =
        useRef<UserDetailsRefreshTrigger | undefined>(undefined);
    const isRefreshingUserDetailsRef = useRef(false);
    const userDetailsRef = useRef<UserDetails | undefined>(undefined);
    const isProductionEndpointRef = useRef(isProductionEndpoint);

    useEffect(
        () => () => {
            mountedRef.current = false;
        },
        [],
    );

    useEffect(() => {
        userDetailsRef.current = userDetails;
    }, [userDetails]);

    useEffect(() => {
        isProductionEndpointRef.current = isProductionEndpoint;
    }, [isProductionEndpoint]);

    const loadUserDetails = useCallback(async (): Promise<LoadUserDetailsResult> => {
        const requestID = ++latestUserDetailsRequestRef.current;
        try {
            const [res, isProduction] = await Promise.all([
                fetch(
                    await apiURL("/users/details/v2", { memoryCount: true }),
                    { headers: await authenticatedRequestHeaders() },
                ),
                isEnteProductionEndpoint(),
            ]);
            ensureOk(res);
            const json = (await res.json()) as LockerUserDetailsResponse;
            const nextUserDetails = {
                email: json.email ?? "",
                usage: json.usage ?? 0,
                storageLimit: json.subscription?.storage ?? 0,
                fileCount: json.fileCount ?? 0,
                lockerFileLimit: hasPaidLockerAccess(json)
                    ? LOCKER_FILE_LIMIT_PAID
                    : LOCKER_FILE_LIMIT_FREE,
                isPartOfFamily: (json.familyData?.members?.length ?? 0) > 0,
                lockerFamilyFileCount: json.lockerFamilyUsage?.familyFileCount,
            };
            const snapshot = {
                isProductionEndpoint: isProduction,
                userDetails: nextUserDetails,
            } satisfies UploadLimitStateSnapshot;

            if (
                !mountedRef.current ||
                requestID !== latestUserDetailsRequestRef.current
            ) {
                return { applied: false, snapshot };
            }

            setIsProductionEndpoint(isProduction);
            setUserDetails(nextUserDetails);
            return { applied: true, snapshot };
        } catch (error) {
            log.error("Failed to fetch user details", error);
            return { applied: false };
        }
    }, []);

    const refreshUserDetailsForSyncState = useCallback(
        async (trigger: UserDetailsRefreshTrigger) => {
            const key = `${trigger.collectionsSinceTime}:${trigger.trashSinceTime}`;
            if (key === lastUserDetailsRefreshKeyRef.current) {
                return;
            }
            if (isRefreshingUserDetailsRef.current) {
                pendingUserDetailsRefreshRef.current = trigger;
                return;
            }

            isRefreshingUserDetailsRef.current = true;
            let pendingTrigger: UserDetailsRefreshTrigger | undefined;
            try {
                const result = await loadUserDetails();
                if (result.applied) {
                    lastUserDetailsRefreshKeyRef.current = key;
                }
            } finally {
                isRefreshingUserDetailsRef.current = false;
                pendingTrigger = pendingUserDetailsRefreshRef.current;
                pendingUserDetailsRefreshRef.current = undefined;
            }

            if (!pendingTrigger) {
                return;
            }

            const pendingKey = `${pendingTrigger.collectionsSinceTime}:${pendingTrigger.trashSinceTime}`;
            if (pendingKey !== lastUserDetailsRefreshKeyRef.current) {
                void refreshUserDetailsForSyncState(pendingTrigger);
            }
        },
        [loadUserDetails],
    );

    const ensureUploadLimitState = useCallback(async () => {
        if (userDetailsRef.current) {
            return {
                isProductionEndpoint: isProductionEndpointRef.current,
                userDetails: userDetailsRef.current,
            } satisfies UploadLimitStateSnapshot;
        }

        const result = await loadUserDetails();
        if (result.snapshot) {
            return result.snapshot;
        }
        return undefined;
    }, [loadUserDetails]);

    const fetchAndStoreLockerData = useCallback(
        async (key: string) => {
            const requestID = ++latestDataRequestRef.current;

            const data = await syncLockerState(key);

            if (
                !mountedRef.current ||
                requestID !== latestDataRequestRef.current
            ) {
                return;
            }

            setCollections(data.collections);
            setTrashItems(data.trashItems);
            setTrashLastUpdatedAt(data.trashLastUpdatedAt);
            setInitialLoadError(null);
            void refreshUserDetailsForSyncState(data);
        },
        [refreshUserDetailsForSyncState],
    );

    const refreshData = useCallback(
        async (mk?: string) => {
            const key = mk ?? masterKey;
            if (!key) {
                return;
            }

            try {
                await fetchAndStoreLockerData(key);
            } catch (error) {
                log.error("Failed to refresh locker data", error);
                if (isHTTP401Error(error)) {
                    showMiniDialog(sessionExpiredDialogAttributes(logout));
                }
            }
        },
        [fetchAndStoreLockerData, logout, masterKey, showMiniDialog],
    );

    useEffect(() => {
        let cancelled = false;
        const canApplyState = () => !cancelled && mountedRef.current;

        const load = async () => {
            try {
                const [mk, token, tokenMismatch] = await Promise.all([
                    masterKeyFromSession(),
                    savedAuthToken(),
                    isSavedUserTokenMismatch(),
                ]);
                if (tokenMismatch || !token) {
                    void logout();
                    return;
                }
                if (!mk) {
                    stashRedirect(router.asPath || "/");
                    void router.push("/login");
                    return;
                }
                if (cancelled || !mountedRef.current) {
                    return;
                }

                setMasterKey(mk);

                const persisted = await loadPersistedLockerState(mk);
                if (canApplyState() && persisted.hasPersistedState) {
                    setCollections(persisted.collections);
                    setTrashItems(persisted.trashItems);
                    setTrashLastUpdatedAt(persisted.trashLastUpdatedAt);
                    setInitialLoadError(null);
                    setHasFetched(true);
                    void refreshUserDetailsForSyncState(persisted);
                }

                await fetchAndStoreLockerData(mk);
            } catch (error) {
                log.error("Failed to fetch locker data", error);
                if (isHTTP401Error(error)) {
                    showMiniDialog(sessionExpiredDialogAttributes(logout));
                }
                if (canApplyState()) {
                    setInitialLoadError(
                        error instanceof Error
                            ? t("failedToLoadCollections", {
                                  error: error.message,
                              })
                            : t("generic_error_retry"),
                    );
                }
            } finally {
                if (canApplyState()) {
                    setHasFetched(true);
                }
            }
        };

        void load();

        return () => {
            cancelled = true;
        };
    }, [fetchAndStoreLockerData, logout, router, showMiniDialog]);

    const removeCollectionFromState = useCallback((collectionID: number) => {
        setCollections((current) =>
            current.filter((collection) => collection.id !== collectionID),
        );
    }, []);

    return {
        collections,
        hasFetched,
        initialLoadError,
        isProductionEndpoint,
        masterKey,
        refreshData,
        removeCollectionFromState,
        trashItems,
        trashLastUpdatedAt,
        userDetails,
        ensureUploadLimitState,
    };
};
