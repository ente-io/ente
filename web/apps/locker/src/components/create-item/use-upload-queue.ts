import {
    formatLockerMutationError,
    lockerUpgradeCTAType,
    type LockerUpgradeCTAType,
} from "@/services/locker-errors";
import {
    exceedsPaidLockerHardLimit,
    validateLockerUploadBatch,
    type LockerUploadLimitState,
    type LockerUploadPreflightFailure,
} from "@/services/locker-limits";
import type { LockerUploadProgress } from "@/services/uploads";
import type { LockerUploadCandidate } from "@/types";
import log from "ente-base/log";
import { t } from "i18next";
import {
    useCallback,
    useState,
    type Dispatch,
    type SetStateAction,
} from "react";
import {
    dedupeCollectionNames,
    fileForUpload,
    filterNonEmptyUploadItems,
    resolveUploadCollectionIDs,
    uploadQueueItemKey,
    type UploadCollectionSelection,
} from "./file-upload-helpers";

const MAX_PARALLEL_UPLOADS = 4;

export interface LockerUploadCallbacks {
    onUploadProgress?: (
        file: File,
        collectionIDs: number[],
        onProgress: (progress: LockerUploadProgress) => void,
    ) => Promise<void>;
    onUploadItemComplete?: () => void;
    onUploadsFinished?: (uploadedCount: number) => Promise<void>;
    onEnsureCollections?: (
        names: string[],
    ) => Promise<Map<string, number> | Record<string, number>>;
    onEnsureUploadLimitState?: () => Promise<
        { userDetails: LockerUploadLimitState } | undefined
    >;
}

interface UseUploadQueueProps extends LockerUploadCallbacks {
    selectedUploadItems: LockerUploadCandidate[];
    selectedCollectionsByFileKey: Record<string, UploadCollectionSelection[]>;
    userDetails?: LockerUploadLimitState;
    setError: Dispatch<SetStateAction<string | null>>;
    setUpgradeCTAType: Dispatch<SetStateAction<LockerUpgradeCTAType | null>>;
}

interface UploadState {
    completedFileKeys: Set<string>;
    failedFileKeys: Set<string>;
    uploadingFileKeys: Set<string>;
    uploadProgressByFileKey: Record<string, LockerUploadProgress | null>;
    uploadCapByFileKey: Record<string, number>;
}

const emptyUploadState = (): UploadState => ({
    completedFileKeys: new Set(),
    failedFileKeys: new Set(),
    uploadingFileKeys: new Set(),
    uploadProgressByFileKey: {},
    uploadCapByFileKey: {},
});

export function useUploadQueue({
    selectedUploadItems,
    selectedCollectionsByFileKey,
    userDetails,
    setError,
    setUpgradeCTAType,
    onUploadProgress,
    onUploadItemComplete,
    onUploadsFinished,
    onEnsureCollections,
    onEnsureUploadLimitState,
}: UseUploadQueueProps) {
    const [uploading, setUploading] = useState(false);
    const [completedFileKeys, setCompletedFileKeys] = useState<Set<string>>(
        () => new Set(),
    );
    const [failedFileKeys, setFailedFileKeys] = useState<Set<string>>(
        () => new Set(),
    );
    const [uploadingFileKeys, setUploadingFileKeys] = useState<Set<string>>(
        () => new Set(),
    );
    const [uploadProgressByFileKey, setUploadProgressByFileKey] = useState<
        Record<string, LockerUploadProgress | null>
    >({});
    const [uploadCapByFileKey, setUploadCapByFileKey] = useState<
        Record<string, number>
    >({});

    const resetUploadState = useCallback(() => {
        const nextState = emptyUploadState();
        setCompletedFileKeys(nextState.completedFileKeys);
        setFailedFileKeys(nextState.failedFileKeys);
        setUploadingFileKeys(nextState.uploadingFileKeys);
        setUploadProgressByFileKey(nextState.uploadProgressByFileKey);
        setUploadCapByFileKey(nextState.uploadCapByFileKey);
    }, []);

    const upload = useCallback(
        async (onComplete: () => void) => {
            if (selectedUploadItems.length === 0 || !onUploadProgress) {
                return;
            }

            const pendingUploadItems = filterNonEmptyUploadItems(
                selectedUploadItems.filter(
                    (item) => !completedFileKeys.has(uploadQueueItemKey(item)),
                ),
            );
            if (pendingUploadItems.length === 0) {
                return;
            }

            let effectiveUserDetails = userDetails;
            if (!effectiveUserDetails) {
                const uploadLimitState = await onEnsureUploadLimitState?.();
                effectiveUserDetails = uploadLimitState?.userDetails;
            }

            if (!effectiveUserDetails) {
                setError(t("generic_error_retry"));
                setUpgradeCTAType(null);
                return;
            }

            const preflightFailure = validateLockerUploadBatch(
                pendingUploadItems.map(({ file }) => file),
                effectiveUserDetails,
            );
            if (preflightFailure) {
                const hitsPaidHardCap = exceedsPaidLockerHardLimit(
                    pendingUploadItems.map(({ file }) => file),
                    effectiveUserDetails,
                );
                const preflightFailureMessage = (
                    failure: LockerUploadPreflightFailure,
                ) => {
                    if (
                        hitsPaidHardCap &&
                        (failure.reason === "fileCountLimit" ||
                            failure.reason === "storageLimit")
                    ) {
                        return t("uploadLockerHardCapErrorBody");
                    }
                    switch (failure.reason) {
                        case "fileCountLimit":
                            return t("uploadFileCountLimitErrorBody");
                        case "fileTooLarge":
                            return t("uploadFileTooLargeErrorBody");
                        case "storageLimit":
                            return t("uploadStorageLimitErrorBody");
                    }
                };

                setError(preflightFailureMessage(preflightFailure));
                setUpgradeCTAType(
                    hitsPaidHardCap
                        ? null
                        : preflightFailure.reason === "fileCountLimit"
                          ? "fileCountLimit"
                          : preflightFailure.reason === "storageLimit"
                            ? "storageLimit"
                            : null,
                );
                return;
            }

            setUploading(true);
            setError(null);
            setUpgradeCTAType(null);
            const pendingUploadFileKeys = new Set(
                pendingUploadItems.map((item) => uploadQueueItemKey(item)),
            );
            setFailedFileKeys((current) => {
                const next = new Set(current);
                pendingUploadFileKeys.forEach((fileKey) =>
                    next.delete(fileKey),
                );
                return next;
            });
            setUploadingFileKeys((current) => {
                const next = new Set(current);
                pendingUploadFileKeys.forEach((fileKey) =>
                    next.delete(fileKey),
                );
                return next;
            });
            setUploadProgressByFileKey((current) =>
                Object.fromEntries(
                    Object.entries(current).filter(
                        ([fileKey]) => !pendingUploadFileKeys.has(fileKey),
                    ),
                ),
            );
            setUploadCapByFileKey((current) =>
                Object.fromEntries(
                    Object.entries(current).filter(
                        ([fileKey]) => !pendingUploadFileKeys.has(fileKey),
                    ),
                ),
            );
            let uploadedCount = 0;
            try {
                const draftNames = dedupeCollectionNames(
                    pendingUploadItems.flatMap((item) =>
                        (
                            selectedCollectionsByFileKey[
                                uploadQueueItemKey(item)
                            ] ?? []
                        ).filter(
                            (selection): selection is string =>
                                typeof selection === "string",
                        ),
                    ),
                );
                const created = draftNames.length
                    ? await onEnsureCollections?.(draftNames)
                    : undefined;
                const createdIDs =
                    created instanceof Map
                        ? created
                        : new Map(Object.entries(created ?? {}));
                const uploadTargets = pendingUploadItems.map((item) => {
                    const fileKey = uploadQueueItemKey(item);
                    const collectionIDs = resolveUploadCollectionIDs(
                        selectedCollectionsByFileKey[fileKey] ?? [],
                        createdIDs,
                    );
                    return { item, fileKey, collectionIDs };
                });

                let nextIndex = 0;
                const worker = async () => {
                    while (true) {
                        const target = uploadTargets[nextIndex];
                        nextIndex += 1;
                        if (!target) {
                            return;
                        }

                        const { item, fileKey, collectionIDs } = target;
                        setUploadingFileKeys((current) =>
                            new Set(current).add(fileKey),
                        );
                        setUploadCapByFileKey((current) => ({
                            ...current,
                            [fileKey]: 90 + Math.floor(Math.random() * 10),
                        }));
                        setUploadProgressByFileKey((current) => ({
                            ...current,
                            [fileKey]: { phase: "preparing" },
                        }));

                        try {
                            await onUploadProgress(
                                fileForUpload(item),
                                collectionIDs,
                                (progress) => {
                                    setUploadProgressByFileKey((current) => ({
                                        ...current,
                                        [fileKey]: progress,
                                    }));
                                },
                            );
                            uploadedCount += 1;
                            setCompletedFileKeys((current) =>
                                new Set(current).add(fileKey),
                            );
                            setFailedFileKeys((current) => {
                                const next = new Set(current);
                                next.delete(fileKey);
                                return next;
                            });
                            onUploadItemComplete?.();
                        } catch (error) {
                            log.error("Failed to upload Locker file", error);
                            const formattedError =
                                await formatLockerMutationError(
                                    error,
                                    "uploadFile",
                                );
                            const nextUpgradeCTAType =
                                await lockerUpgradeCTAType(error);
                            setError((current) => current ?? formattedError);
                            if (nextUpgradeCTAType) {
                                setUpgradeCTAType(
                                    (current) => current ?? nextUpgradeCTAType,
                                );
                            }
                            setFailedFileKeys((current) =>
                                new Set(current).add(fileKey),
                            );
                        } finally {
                            setUploadingFileKeys((current) => {
                                const next = new Set(current);
                                next.delete(fileKey);
                                return next;
                            });
                        }
                    }
                };

                await Promise.all(
                    Array.from({
                        length: Math.min(
                            MAX_PARALLEL_UPLOADS,
                            pendingUploadItems.length,
                        ),
                    }).map(() => worker()),
                );

                if (uploadedCount > 0) {
                    await onUploadsFinished?.(uploadedCount);
                }
                if (
                    completedFileKeys.size + uploadedCount ===
                    selectedUploadItems.length
                ) {
                    onComplete();
                }
            } catch (error) {
                log.error("Failed to upload Locker files", error);
                setError(await formatLockerMutationError(error, "uploadFile"));
                setUpgradeCTAType(await lockerUpgradeCTAType(error));
            } finally {
                setUploading(false);
            }
        },
        [
            completedFileKeys,
            onEnsureCollections,
            onEnsureUploadLimitState,
            onUploadItemComplete,
            onUploadProgress,
            onUploadsFinished,
            selectedCollectionsByFileKey,
            selectedUploadItems,
            userDetails,
            setError,
            setUpgradeCTAType,
        ],
    );

    return {
        uploading,
        completedFileKeys,
        failedFileKeys,
        uploadingFileKeys,
        uploadProgressByFileKey,
        uploadCapByFileKey,
        resetUploadState,
        upload,
    };
}
