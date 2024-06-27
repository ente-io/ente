import { getLocalTrashedFiles } from "@/new/photos/services/files";
import { authenticatedRequestHeaders } from "@/next/http";
import { apiURL } from "@/next/origins";
import log from "@/next/log";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import { decryptFileMetadata } from "../../common/crypto/ente";
import { getAllLocalFiles } from "./files";

/**
 * The embeddings that we (the current client) knows how to handle.
 *
 * This is an exhaustive set of values we pass when GET-ing or PUT-ting
 * encrypted embeddings from remote. However, we should be prepared to receive a
 * {@link RemoteEmbedding} with a model value different from these.
 *
 * It is vernacularly called a model, but strictly speaking this is not the
 * model, but the embedding produced by a particular model with a particular set
 * of pre-/post- processing steps and related hyperparameters. It is better
 * thought of as an "type" of embedding produced or consumed by the client.
 *
 * [Note: Handling versioning of embeddings]
 *
 * The embeddings themselves have a version included in them, so it is possible
 * for us to make backward compatible updates to the indexing process on newer
 * clients.
 *
 * If we bump the version of same model (say when indexing on a newer client),
 * the assumption will be that older client will be able to consume the
 * response. Say if we improve blur detection, older client should just consume
 * the newer version and not try to index the file locally.
 *
 * If you get version that is older, client should discard and try to index
 * locally (if needed) and also put the newer version it has on remote.
 *
 * In the case where the changes are not backward compatible and can only be
 * consumed by clients with the relevant scaffolding, then we change this
 * "model" (i.e "type") field to create a new universe of embeddings.
 */
export type EmbeddingModel =
    | "onnx-clip" /* CLIP (text) embeddings */
    | "file-ml-clip-face" /* Face embeddings */;

const RemoteEmbedding = z.object({
    /** The ID of the file whose embedding this is. */
    fileID: z.number(),
    /**
     * The embedding "type".
     *
     * This can be an arbitrary string since there might be models the current
     * client does not know about; we limit our interactions to values that are
     * one of {@link EmbeddingModel}.
     */
    model: z.string(),
    /**
     * Base64 representation of the encrypted (model specific) embedding JSON.
     */
    encryptedEmbedding: z.string(),
    /**
     * Base64 representation of the header that should be passed when decrypting
     * {@link encryptedEmbedding}. See the {@link decryptMetadata} function in
     * the crypto layer.
     */
    decryptionHeader: z.string(),
    /** Last time (epoch ms) this embedding was updated. */
    updatedAt: z.number(),
    /**
     * The version for the embedding. Optional.
     *
     * See: [Note: Handling versioning of embeddings]
     */
    version: z.number().nullish().transform(nullToUndefined),
});

type RemoteEmbedding = z.infer<typeof RemoteEmbedding>;

/**
 * Fetch new or updated face embeddings from remote and save them locally.
 *
 * It takes no parameters since it saves the last sync time in local storage.
 *
 * This function should be called only after we have synced files with remote.
 * See: [Note: Ignoring embeddings for unknown files].
 */
export const pullRemoteFaceEmbeddings = async () => {
    // Include files from trash, otherwise they'll get unnecessarily reindexed
    // if the user restores them from trash before permanent deletion.
    const localFiles = (await getAllLocalFiles()).concat(
        await getLocalTrashedFiles(),
    );
    const localFilesByID = new Map(localFiles.map((f) => [f.id, f]));

    const decryptEmbedding = async (remoteEmbedding: RemoteEmbedding) => {
        const file = localFilesByID.get(remoteEmbedding.fileID);
        // [Note: Ignoring embeddings for unknown files]
        //
        // We need the file to decrypt the embedding. This is easily ensured by
        // running the embedding sync after we have synced our local files with
        // remote.
        //
        // Still, it might happen that we come across an embedding for which we
        // don't have the corresponding file locally. We can put them in two
        // buckets:
        //
        // 1.  Known case: In rare cases we might get a diff entry for an
        //     embedding corresponding to a file which has been deleted (but
        //     whose embedding is enqueued for deletion). Client should expect
        //     such a scenario, but all they have to do is just ignore such
        //     embeddings.
        //
        // 2.  Other unknown cases: Even if somehow we end up with an embedding
        //     for a existent file which we don't have locally, it is fine
        //     because the current client will just regenerate the embedding if
        //     the file really exists and gets locally found later. There would
        //     be a bit of duplicate work, but that's fine as long as there
        //     isn't a systematic scenario where this happens.
        if (!file) return undefined;
        try {
            const decryptedString = await decryptFileMetadata(
                remoteEmbedding.encryptedEmbedding,
                remoteEmbedding.decryptionHeader,
                file.key,
            );
            return decryptedString;
        } catch (e) {
            log.warn("Ignoring unparseable embedding", e);
            return undefined;
        }
    };

    let sinceTime = faceEmbeddingSyncTime();

    // TODO: eslint has fixed this spurious warning, but we're not on the latest
    // version yet, so add a disable.
    // https://github.com/eslint/eslint/pull/18286
    /* eslint-disable no-constant-condition */
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    while (true) {
        const remoteEmbeddings = await getEmbeddingsDiff(
            "file-ml-clip-face",
            sinceTime,
        );
        if (remoteEmbeddings.length == 0) break;
        void (await Promise.all(remoteEmbeddings.map(decryptEmbedding)));
        sinceTime = remoteEmbeddings.reduce(
            (max, { updatedAt }) => Math.max(max, updatedAt),
            sinceTime,
        );
        saveFaceEmbeddingSyncTime(sinceTime);
    }
};

// const decryptFaceEmbedding = async (remoteEmbedding: RemoteEmbedding) => {
//                         const fileKey = fileIdToKeyMap.get(embedding.fileID);
//                         if (!fileKey) {
//                             throw Error(CustomError.FILE_NOT_FOUND);
//                         }
//                         const decryptedData = await worker.decryptMetadata(
//                             embedding.encryptedEmbedding,
//                             embedding.decryptionHeader,
//                             fileIdToKeyMap.get(embedding.fileID),
//                         );
//                         return {
//                             ...decryptedData,
//                             updatedAt: embedding.updatedAt,
//                         } as unknown as FileML;
// };

/**
 * The updatedAt of the most recent face {@link RemoteEmbedding} we've retrieved
 * and saved from remote, or 0.
 *
 * This value is persisted to local storage. To update it, use
 * {@link saveFaceEmbeddingSyncMarker}.
 */
const faceEmbeddingSyncTime = () =>
    parseInt(localStorage.getItem("faceEmbeddingSyncTime") ?? "0");

/** Sibling of {@link faceEmbeddingSyncMarker}. */
const saveFaceEmbeddingSyncTime = (t: number) =>
    localStorage.setItem("faceEmbeddingSyncTime", `${t}`);

/**
 * Zod schemas for the {@link FaceIndex} types.
 *
 * [Note: Duplicated between Zod schemas and TS type]
 *
 * Usually we define a Zod schema, and then infer the corresponding TypeScript
 * type for it using `z.infer`. This works great except now the docstrings don't
 * show up: The doc strings get added to the Zod schema, but usually the code
 * using the parsed data will reference the TypeScript type, and the docstrings
 * added to the fields in the Zod schema won't show up.
 *
 * We usually live with this infelicity, since the alternative is code
 * duplication: Define the TypeScript type (putting the docstrings therein)
 * _and_ also a corresponding Zod schema. The duplication happens because it is
 * not possible to go the other way (TS type => Zod schema).
 *
 * However, in some cases having when the TypeScript type under consideration is
 * used pervasely in our code, having a standalone TypeScript type with attached
 * docstrings, is worth the code duplication.
 *
 * Note that this'll just be syntactic duplication - if the two definitions get
 * out of sync in the shape of the types they represent, the TypeScript compiler
 * will flag it for us.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const FaceIndex = z
    .object({
        fileID: z.number(),
        width: z.number(),
        height: z.number(),
        faceEmbedding: z
            .object({
                version: z.number(),
                client: z.string(),
                faces: z.array(
                    z
                        .object({
                            faceID: z.string(),
                            detection: z
                                .object({
                                    box: z
                                        .object({
                                            x: z.number(),
                                            y: z.number(),
                                            width: z.number(),
                                            height: z.number(),
                                        })
                                        .passthrough(),
                                    landmarks: z.array(
                                        z
                                            .object({
                                                x: z.number(),
                                                y: z.number(),
                                            })
                                            .passthrough(),
                                    ),
                                })
                                .passthrough(),
                            score: z.number(),
                            blur: z.number(),
                            embedding: z.array(z.number()),
                        })
                        .passthrough(),
                ),
            })
            .passthrough(),
    })
    // Retain fields we might not (currently) understand.
    .passthrough();

/**
 * The maximum number of items to fetch in a single GET /embeddings/diff
 *
 * [Note: Limit of returned items in /diff requests]
 *
 * The various GET /diff API methods, which tell the client what all has changed
 * since a timestamp (provided by the client) take a limit parameter.
 *
 * These diff API calls return all items whose updated at is greater
 * (non-inclusive) than the timestamp we provide. So there is no mechanism for
 * pagination of items which have the same exact updated at. Conceptually, it
 * may happen that there are more items than the limit we've provided.
 *
 * The behaviour of this limit is different for file diff and embeddings diff.
 *
 * -   For file diff, the limit is advisory, and remote may return less, equal
 *     or more items than the provided limit. The scenario where it returns more
 *     is when more files than the limit have the same updated at. Theoretically
 *     it would make the diff response unbounded, however in practice file
 *     modifications themselves are all batched. Even if the user selects all
 *     the files in their library and updates them all in one go in the UI,
 *     their client app must use batched API calls to make those updates, and
 *     each of those batches would get distinct updated at.
 *
 * -   For embeddings diff, there are no bulk updates and this limit is enforced
 *     as a maximum. While theoretically it is possible for an arbitrary number
 *     of files to have the same updated at, in practice it is not possible with
 *     the current set of APIs where clients PUT individual embeddings (the
 *     updated at is a server timestamp). And even if somehow a large number of
 *     files get the same updated at and thus get truncated in the response, it
 *     won't lead to any data loss, the client which requested that particular
 *     truncated diff will just regenerate them.
 */
const diffLimit = 500;

/**
 * GET embeddings for the given model that have been updated {@link sinceTime}.
 *
 * This fetches the next {@link diffLimit} embeddings whose {@link updatedAt} is
 * greater than the given {@link sinceTime} (non-inclusive).
 *
 * @param model The {@link EmbeddingModel} whose diff we wish for.
 *
 * @param sinceTime The updatedAt of the last embedding we've synced (epoch ms).
 * Pass 0 to fetch everything from the beginning.
 *
 * @returns an array of {@link RemoteEmbedding}. The returned array is limited
 * to a maximum count of {@link diffLimit}.
 *
 * > See [Note: Limit of returned items in /diff requests].
 */
const getEmbeddingsDiff = async (
    model: EmbeddingModel,
    sinceTime: number,
): Promise<RemoteEmbedding[]> => {
    const params = new URLSearchParams({
        model,
        sinceTime: `${sinceTime}`,
        limit: `${diffLimit}`,
    });
    const url = await apiURL("/embeddings/diff");
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: authenticatedRequestHeaders(),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    return z.array(RemoteEmbedding).parse(await res.json());
};
