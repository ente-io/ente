import { authenticatedRequestHeaders } from "@/next/http";
import { apiOrigin } from "@/next/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

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

/** The maximum number of items to fetch in a single GET /embeddings/diff */
const diffLimit = 500;

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

/**
 * Ask remote for what all changes have happened to the face embeddings that it
 * knows about since the last time we synced. Then update our local state to
 * reflect those changes.
 *
 * It takes no parameters since it saves the last sync time in local storage.
 */
export const syncRemoteFaceEmbeddings = async () => {
    return 0;
};

// const getFaceEmbeddings = async () => {

// }

/**
 * GET /embeddings/diff for the given model and changes {@link sinceTime}.
 *
 * @param model The {@link EmbeddingModel} whose diff we wish for.
 *
 * @param sinceTime The last time we synced (epoch ms). Pass 0 to fetch
 * everything from the beginning.
 */
const getEmbeddingsDiff = async (model: EmbeddingModel, sinceTime: number) => {
    const params = new URLSearchParams({model, sinceTime: `${sinceTime}`, limit: `${diffLimit}`})
    const url = `${apiOrigin()}/embeddings/diff`;
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: authenticatedRequestHeaders(),
    })
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
}

