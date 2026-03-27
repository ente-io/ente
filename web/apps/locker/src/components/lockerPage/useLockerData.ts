import { sessionExpiredDialogAttributes } from "ente-accounts-rs/components/utils/dialog";
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
import { t } from "i18next";
import type { NextRouter } from "next/router";
import { useCallback, useEffect, useRef, useState } from "react";
import {
    isEnteProductionEndpoint,
    LOCKER_FILE_LIMIT_FREE,
    LOCKER_FILE_LIMIT_PAID,
} from "services/locker-limits";
import { fetchLockerData, fetchLockerTrash } from "services/remote";
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

export interface UserDetails {
    email: string;
    usage: number;
    storageLimit: number;
    fileCount: number;
    lockerFileLimit: number;
    isPartOfFamily: boolean;
    lockerFamilyFileCount?: number;
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

    useEffect(
        () => () => {
            mountedRef.current = false;
        },
        [],
    );

    const loadUserDetails = useCallback(async () => {
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

            if (
                !mountedRef.current ||
                requestID !== latestUserDetailsRequestRef.current
            ) {
                return;
            }

            setIsProductionEndpoint(isProduction);
            const json = (await res.json()) as LockerUserDetailsResponse;
            setUserDetails({
                email: json.email ?? "",
                usage: json.usage ?? 0,
                storageLimit: json.subscription?.storage ?? 0,
                fileCount: json.fileCount ?? 0,
                lockerFileLimit: hasPaidLockerAccess(json)
                    ? LOCKER_FILE_LIMIT_PAID
                    : LOCKER_FILE_LIMIT_FREE,
                isPartOfFamily: (json.familyData?.members?.length ?? 0) > 0,
                lockerFamilyFileCount: json.lockerFamilyUsage?.familyFileCount,
            });
        } catch (error) {
            log.error("Failed to fetch user details", error);
        }
    }, []);

    const fetchAndStoreLockerData = useCallback(
        async (key: string) => {
            const requestID = ++latestDataRequestRef.current;
            void loadUserDetails();

            const data = await fetchLockerData(key);
            const trash = await fetchLockerTrash(key);

            if (
                !mountedRef.current ||
                requestID !== latestDataRequestRef.current
            ) {
                return;
            }

            setCollections(data);
            setTrashItems(trash.items);
            setTrashLastUpdatedAt(trash.lastUpdatedAt);
            setInitialLoadError(null);
        },
        [loadUserDetails],
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
            const mk = await masterKeyFromSession();
            if (!mk) {
                stashRedirect(router.asPath || "/");
                void router.push("/login");
                return;
            }
            if (cancelled || !mountedRef.current) {
                return;
            }

            setMasterKey(mk);

            try {
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
    };
};
