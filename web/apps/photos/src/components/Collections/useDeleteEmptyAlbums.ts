import type { RemotePullOpts } from "@/components/gallery";
import { ensureLocalUser } from "ente-accounts/services/user";
import {
    deleteCollection,
    isArchivedCollection,
    isDefaultHiddenCollection,
} from "ente-new/photos/services/collection";
import {
    isBulkDeletableEmptyAlbum,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { t } from "i18next";
import { useState } from "react";

export const useDeleteEmptyAlbums = (
    collectionSummaries: CollectionSummary[],
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>,
) => {
    const [candidateIDs, setCandidateIDs] = useState<number[]>();
    const { showNotification } = usePhotosAppContext();
    const emptyAlbumCandidates = collectionSummaries.filter(
        isBulkDeletableEmptyAlbum,
    );

    const deleteEmptyAlbums = async (candidateIDs: number[]) => {
        let failedCount = 0;
        let confirmedCandidateIDs: number[];

        try {
            await onRemotePull({ strict: true });

            const [collections, collectionFiles] = await Promise.all([
                savedCollections(),
                savedCollectionFiles(),
            ]);
            const candidateIDSet = new Set(candidateIDs);
            const nonEmptyCollectionIDs = new Set(
                collectionFiles.map((file) => file.collectionID),
            );
            const userID = ensureLocalUser().id;
            confirmedCandidateIDs = collections
                .filter(
                    (collection) =>
                        candidateIDSet.has(collection.id) &&
                        !nonEmptyCollectionIDs.has(collection.id) &&
                        (collection.type == "album" ||
                            collection.type == "folder") &&
                        collection.owner.id == userID &&
                        !collection.sharees.length &&
                        !collection.publicURLs.length &&
                        !isArchivedCollection(collection) &&
                        !isDefaultHiddenCollection(collection),
                )
                .map((collection) => collection.id);
        } catch {
            showNotification({
                color: "critical",
                title: t("delete_empty_albums_failed", {
                    count: candidateIDs.length,
                }),
            });
            return;
        }

        if (!confirmedCandidateIDs.length) return;

        for (const id of confirmedCandidateIDs) {
            try {
                await deleteCollection(id, { keepFiles: true });
            } catch {
                failedCount++;
            }
        }

        let refreshFailed = false;
        try {
            await onRemotePull({ strict: true });
        } catch {
            refreshFailed = true;
        }

        if (failedCount > 0) {
            showNotification({
                color: "critical",
                title: t("delete_empty_albums_failed", { count: failedCount }),
            });
        } else if (refreshFailed) {
            showNotification({
                color: "critical",
                title: t("delete_empty_albums_refresh_failed"),
            });
        }
    };

    const handleDeleteEmptyAlbums = () => {
        setCandidateIDs(emptyAlbumCandidates.map((cs) => cs.id));
    };

    return {
        handleDeleteEmptyAlbums,
        deleteEmptyAlbumsDialogProps: {
            open: candidateIDs !== undefined,
            onClose: () => setCandidateIDs(undefined),
            count: candidateIDs?.length ?? 0,
            title: t("delete_empty_albums_title"),
            message: t("delete_empty_albums_message", {
                count: candidateIDs?.length ?? 0,
            }),
            confirmText: t("delete"),
            onConfirm: () => deleteEmptyAlbums(candidateIDs ?? []),
        },
        hasEnoughEmptyAlbums: emptyAlbumCandidates.length >= 3,
    };
};
