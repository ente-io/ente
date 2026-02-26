import { CollectionSubType, type Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import {
    addToCollection,
    createPublicURL,
    createQuickLinkCollection,
} from "ente-new/photos/services/collection";
import { quickLinkNameForFiles, resolveQuickLinkURL } from "utils/quick-link";

interface FindReusableSingleFileQuickLinkCollectionParams {
    file: EnteFile;
    userID: number;
    collections: Collection[];
    collectionFiles: EnteFile[];
}

export const findReusableSingleFileQuickLinkCollection = ({
    file,
    userID,
    collections,
    collectionFiles,
}: FindReusableSingleFileQuickLinkCollectionParams) => {
    const quickLinkCollections = collections.filter(
        (collection) =>
            collection.owner.id == userID &&
            collection.magicMetadata?.data.subType ==
                CollectionSubType.quicklink,
    );
    if (!quickLinkCollections.length) return undefined;

    const quickLinkCollectionIDs = new Set(
        quickLinkCollections.map((c) => c.id),
    );
    const quickLinkFileIDsByCollectionID = new Map<number, Set<number>>();
    for (const collectionFile of collectionFiles) {
        if (!quickLinkCollectionIDs.has(collectionFile.collectionID)) continue;

        let fileIDs = quickLinkFileIDsByCollectionID.get(
            collectionFile.collectionID,
        );
        if (!fileIDs) {
            quickLinkFileIDsByCollectionID.set(
                collectionFile.collectionID,
                (fileIDs = new Set<number>()),
            );
        }
        fileIDs.add(collectionFile.id);
    }

    let reusableCollection: Collection | undefined;
    for (const collection of quickLinkCollections) {
        const fileIDs = quickLinkFileIDsByCollectionID.get(collection.id);
        if (!fileIDs || fileIDs.size != 1 || !fileIDs.has(file.id)) continue;
        if (
            !reusableCollection ||
            collection.updationTime > reusableCollection.updationTime
        ) {
            reusableCollection = collection;
        }
    }

    return reusableCollection;
};

interface CreateOrReuseQuickLinkURLForFilesParams {
    files: EnteFile[];
    userID: number;
    collections: Collection[];
    collectionFiles: EnteFile[];
    customDomain: string | undefined;
}

interface CreateOrReuseQuickLinkURLForFilesResult {
    url: string;
    shouldPull: boolean;
}

const isPublicURLExpired = (validTill: number) =>
    validTill > 0 && validTill < Date.now() * 1000;

export const createOrReuseQuickLinkURLForFiles = async ({
    files,
    userID,
    collections,
    collectionFiles,
    customDomain,
}: CreateOrReuseQuickLinkURLForFilesParams): Promise<
    CreateOrReuseQuickLinkURLForFilesResult | undefined
> => {
    if (!files.length) return undefined;

    let quickLinkCollection: Collection;
    let publicURL: string;
    let shouldPull = false;

    const singleFile = files[0];
    if (files.length == 1 && singleFile) {
        const reusableCollection = findReusableSingleFileQuickLinkCollection({
            file: singleFile,
            userID,
            collections,
            collectionFiles,
        });
        if (reusableCollection) {
            quickLinkCollection = reusableCollection;
            const reusablePublicURL = reusableCollection.publicURLs.find(
                (publicURL) =>
                    !!publicURL.url &&
                    !publicURL.enableJoin &&
                    !isPublicURLExpired(publicURL.validTill),
            );
            publicURL = reusablePublicURL?.url ?? "";
            if (!publicURL) {
                publicURL = (
                    await createPublicURL(quickLinkCollection.id, {
                        enableJoin: false,
                    })
                ).url;
                shouldPull = true;
            }
        } else {
            quickLinkCollection = await createQuickLinkCollection(
                quickLinkNameForFiles(files),
            );
            await addToCollection(quickLinkCollection, files);
            publicURL = (
                await createPublicURL(quickLinkCollection.id, {
                    enableJoin: false,
                })
            ).url;
            shouldPull = true;
        }
    } else {
        quickLinkCollection = await createQuickLinkCollection(
            quickLinkNameForFiles(files),
        );
        await addToCollection(quickLinkCollection, files);
        publicURL = (
            await createPublicURL(quickLinkCollection.id, { enableJoin: false })
        ).url;
        shouldPull = true;
    }

    const url = await resolveQuickLinkURL(
        publicURL,
        quickLinkCollection.key,
        customDomain,
    );

    return { url, shouldPull };
};
