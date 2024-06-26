import { authenticatedRequestHeaders } from "@/next/http";
import { apiOrigin } from "@/next/origins";

/**
 * The embeddings that we (the current client) knows how to handle.
 *
 * It is vernacularly called a model, but strictly speaking this is not the
 * model, but the embedding produced by a particular model with a particular set
 * of pre-/post- processing steps and related hyperparameters. It is better
 * thought of as an "type" of embedding produced or consumed by the client.
 *
 * The embeddings themselves have a version included in them, so it is possible
 * for us to make backward compatible updates to the indexing process on newer
 * clients. Alternatively, if the changes are not backward compatible and can
 * only be consumed by clients with the relevant scaffolding, then we change
 * this "model" (i.e "type") field to create a new universe of embeddings.
 *
 * This is an exhaustive set of values we pass when GET-ing or PUT-ting
 * encrypted embeddings from remote. However, we should be prepared to receive
 * an {@link EncryptedEmbedding} with a model value different from these.
 */
export type EmbeddingModel = "onnx-clip" | "file-ml-clip-face";

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

/** The maximum number of items to fetch in a single GET /embeddings/diff */
const diffLimit = 500;

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

