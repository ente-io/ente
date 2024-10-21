import { stashRedirect } from "@/accounts/services/redirect";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { ALL_SECTION } from "@/new/photos/services/collection";
import { createFileCollectionIDs } from "@/new/photos/services/file";
import { getLocalFiles } from "@/new/photos/services/files";
import { AppContext } from "@/new/photos/types/context";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { ApiError } from "@ente/shared/error";
import useMemoSingleThreaded from "@ente/shared/hooks/useMemoSingleThreaded";
import { SESSION_KEYS, getKey } from "@ente/shared/storage/sessionStorage";
import { styled } from "@mui/material";
import Typography from "@mui/material/Typography";
import { HttpStatusCode } from "axios";
import DeduplicateOptions from "components/pages/dedupe/SelectedFileOptions";
import PhotoFrame from "components/PhotoFrame";
import { t } from "i18next";
import { default as Router, default as router } from "next/router";
import { createContext, useContext, useEffect, useState } from "react";
import {
    getAllLatestCollections,
    getLocalCollections,
} from "services/collectionService";
import { Duplicate, getDuplicates } from "services/deduplicationService";
import { syncFiles, trashFiles } from "services/fileService";
import { syncTrash } from "services/trashService";
import {
    DeduplicateContextType,
    DefaultDeduplicateContext,
} from "types/deduplicate";
import { SelectedState } from "types/gallery";
import { getSelectedFiles } from "utils/file";

export const DeduplicateContext = createContext<DeduplicateContextType>(
    DefaultDeduplicateContext,
);
export const Info = styled("div")`
    padding: 24px;
    font-size: 18px;
`;

export default function Deduplicate() {
    const { setDialogMessage, startLoading, finishLoading, showNavBar } =
        useContext(AppContext);
    const [duplicates, setDuplicates] = useState<Duplicate[]>(null);
    const [collectionNameMap, setCollectionNameMap] = useState(
        new Map<number, string>(),
    );
    const [selected, setSelected] = useState<SelectedState>({
        count: 0,
        collectionID: 0,
        ownCount: 0,
        context: undefined,
    });
    const closeDeduplication = function () {
        Router.push(PAGES.GALLERY);
    };
    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            stashRedirect(PAGES.DEDUPLICATE);
            router.push("/");
            return;
        }
        showNavBar(true);
    }, []);

    useEffect(() => {
        syncWithRemote();
    }, []);

    const syncWithRemote = async () => {
        startLoading();
        const collections = await getLocalCollections();
        const collectionNameMap = new Map<number, string>();
        for (const collection of collections) {
            collectionNameMap.set(collection.id, collection.name);
        }
        setCollectionNameMap(collectionNameMap);
        const files = await getLocalFiles();
        const duplicateFiles = await getDuplicates(files, collectionNameMap);
        const currFileSizeMap = new Map<number, number>();
        let toSelectFileIDs: number[] = [];
        let count = 0;
        for (const dupe of duplicateFiles) {
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
        setDuplicates(duplicateFiles);
        const selectedFiles = {
            count: count,
            ownCount: count,
            collectionID: ALL_SECTION,
            context: undefined,
        };
        for (const fileID of toSelectFileIDs) {
            selectedFiles[fileID] = true;
        }
        setSelected(selectedFiles);
        finishLoading();
    };

    const duplicateFiles = useMemoSingleThreaded(() => {
        return (duplicates ?? []).reduce((acc, dupe) => {
            return [...acc, ...dupe.files];
        }, []);
    }, [duplicates]);

    const fileToCollectionsMap = useMemoSingleThreaded(() => {
        return createFileCollectionIDs(duplicateFiles ?? []);
    }, [duplicateFiles]);

    const deleteFileHelper = async () => {
        try {
            startLoading();
            const selectedFiles = getSelectedFiles(selected, duplicateFiles);
            await trashFiles(selectedFiles);

            // trashFiles above does an API request, we still need to update our
            // local state.
            //
            // Enhancement: This can be done in a more granular manner. Also, it
            // is better to funnel these syncs instead of adding these here and
            // there in an ad-hoc manner. For now, this fixes the issue with the
            // UI not updating if the user deletes only some of the duplicates.
            const collections = await getAllLatestCollections();
            await syncFiles(
                "normal",
                collections,
                () => {},
                () => {},
            );
            await syncTrash(collections, () => {});
        } catch (e) {
            if (
                e instanceof ApiError &&
                e.httpStatusCode === HttpStatusCode.Forbidden
            ) {
                setDialogMessage({
                    title: t("error"),

                    close: { variant: "critical" },
                    content: t("NOT_FILE_OWNER"),
                });
            } else {
                setDialogMessage({
                    title: t("error"),

                    close: { variant: "critical" },
                    content: t("generic_error_retry"),
                });
            }
        } finally {
            await syncWithRemote();
            finishLoading();
        }
    };

    const clearSelection = function () {
        setSelected({
            count: 0,
            collectionID: 0,
            ownCount: 0,
            context: undefined,
        });
    };

    if (!duplicates) {
        return (
            <VerticallyCentered>
                <ActivityIndicator />
            </VerticallyCentered>
        );
    }

    return (
        <DeduplicateContext.Provider
            value={{
                ...DefaultDeduplicateContext,
                collectionNameMap,
                isOnDeduplicatePage: true,
            }}
        >
            {duplicateFiles.length > 0 && (
                <Info>{t("DEDUPLICATE_BASED_ON_SIZE")}</Info>
            )}
            {duplicateFiles.length === 0 ? (
                <VerticallyCentered>
                    <Typography variant="large" color="text.muted">
                        {t("NO_DUPLICATES_FOUND")}
                    </Typography>
                </VerticallyCentered>
            ) : (
                <PhotoFrame
                    page={PAGES.DEDUPLICATE}
                    files={duplicateFiles}
                    duplicates={duplicates}
                    syncWithRemote={syncWithRemote}
                    setSelected={setSelected}
                    selected={selected}
                    activeCollectionID={ALL_SECTION}
                    fileToCollectionsMap={fileToCollectionsMap}
                    collectionNameMap={collectionNameMap}
                    selectable={true}
                />
            )}
            <DeduplicateOptions
                deleteFileHelper={deleteFileHelper}
                count={selected.count}
                close={closeDeduplication}
                clearSelection={clearSelection}
            />
        </DeduplicateContext.Provider>
    );
}
