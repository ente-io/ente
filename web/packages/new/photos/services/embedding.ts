import { authenticatedRequestHeaders } from "@/next/http";
import { apiURL } from "@/next/origins";
import { nullToUndefined } from "@/utils/transform";
// import ComlinkCryptoWorker from "@ente/shared/crypto";
import { z } from "zod";
// import { getAllLocalFiles } from "./files";

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
 * Ask remote for what all changes have happened to the face embeddings that it
 * knows about since the last time we synced. Then update our local state to
 * reflect those changes.
 *
 * It takes no parameters since it saves the last sync time in local storage.
 */
export const syncRemoteFaceEmbeddings = async () => {
    let sinceTime = faceEmbeddingSyncTime();
    // const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    // const files = await getAllLocalFiles();

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
        // const _embeddings = Promise.all(
        //     remoteEmbeddings.map(decryptFaceEmbedding),
        // );
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

// const getFaceEmbeddings = async () => {

// }

/** The maximum number of items to fetch in a single GET /embeddings/diff */
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
