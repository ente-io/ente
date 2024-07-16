import {
    getAllLocalFiles,
    getLocalTrashedFiles,
} from "@/new/photos/services/files";
import type { EnteFile } from "@/new/photos/types/file";
import {
    decryptFileMetadataString,
    encryptFileMetadata,
} from "@/new/shared/crypto/ente";
import { authenticatedRequestHeaders, ensureOk } from "@/next/http";
import { getKV, setKV } from "@/next/kv";
import log from "@/next/log";
import { apiURL } from "@/next/origins";
import { z } from "zod";
import { clipIndexingVersion, type CLIPIndex } from "./clip";
import { saveCLIPIndex, saveFaceIndex } from "./db";
import {
    faceIndexingVersion,
    type FaceIndex,
    type RemoteFaceIndex,
} from "./face";

/**
 * The embeddings that we (the current client) knows how to handle.
 *
 * This is an exhaustive set of values we pass when GET-ing or PUT-ting
 * encrypted embeddings from remote. However, we should be prepared to receive a
 * {@link RemoteEmbedding} with a model value different from these.
 *
 * [Note: Embedding/model vs derived data]
 *
 * Historically, this has been called an "embedding" or a "model" in the API
 * terminology. However, it is more like derived data.
 *
 * It started off being called as "model", but strictly speaking it was not just
 * the model, but the embedding produced by a particular ML model when used with
 * a particular set of pre-/post- processing steps and related hyperparameters.
 * It is better thought of as an "type" of embedding produced or consumed by the
 * client, e.g. the "face" embedding, or the "clip" embedding.
 *
 * Even the word embedding is a synedoche, since it might have other data. For
 * example, for faces, it in not just the face embedding, but also the detection
 * regions, landmarks etc: What we've come to refer as the "face index" in our
 * client code terminology.
 *
 * Later on, to avoid the proliferation of small files (one per embedding), we
 * combined all these embeddings into a single "embedding", which is a map of
 * the form:
 *
 *     {
 *       "face": ... the face indexing result ...
 *       "clip": ... the CLIP indexing result ...
 *       "exif": ... the Exif extracted from the file ...
 *       ... more in the future ...
 *     }
 *
 * Thus, now this is best thought of a tag for a particular format of encoding
 * all the derived data associated with a file.
 *
 * [Note: Handling versioning of embeddings]
 *
 * The embeddings themselves have a version embedded in them, so it is possible
 * for us to make backward compatible updates to the indexing process on newer
 * clients (There is also a top level version field too but that is not used).
 *
 * If we bump the version of same model (say when indexing on a newer client),
 * the assumption will be that older client will be able to consume the
 * response. e.g.  Say if we improve blur detection, older client should just
 * consume embeddings with a newer version and not try to index the file again
 * locally.
 *
 * If we get an embedding with version that is older than the version the client
 * supports, then the client should ignore it. This way, the file will get
 * reindexed locally an embedding with a newer version will get put to remote.
 *
 * In the case where the changes are not backward compatible and can only be
 * consumed by clients with the relevant scaffolding, then we change this
 * "model" (i.e "type") field to create a new universe of embeddings.
 */
export type EmbeddingModel =
    // TODO-ML: prune
    | "onnx-clip" /* CLIP embeddings */
    | "file-ml-clip-face" /* Face embeddings */
    | "combined" /* Combined format */;

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
});

type RemoteEmbedding = z.infer<typeof RemoteEmbedding>;

/**
 * Fetch new or updated embeddings from remote and save them locally.
 *
 * @param model The {@link EmbeddingModel} for which to pull embeddings. For
 * each model, this function maintains the last sync time in local storage so
 * subsequent fetches only pull what's new.
 *
 * @param save A function that is called to save the embedding. The save process
 * can be model specific, so this provides us a hook to reuse the surrounding
 * pull mechanisms while varying the save itself. This function will be passed
 * the decrypted embedding string. If it throws, then we'll log about but
 * otherwise ignore the embedding under consideration.
 *
 * This function should be called only after we have synced files with remote.
 * See: [Note: Ignoring embeddings for unknown files].
 *
 * @returns true if at least one embedding was pulled, false otherwise.
 */
const pullEmbeddings = async (
    model: EmbeddingModel,
    save: (decryptedEmbedding: string) => Promise<void>,
) => {
    // Include files from trash, otherwise they'll get unnecessarily reindexed
    // if the user restores them from trash before permanent deletion.
    const localFiles = (await getAllLocalFiles()).concat(
        await getLocalTrashedFiles(),
    );
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
    // 1.  Known case: In rare cases we might get a diff entry for an embedding
    //     corresponding to a file which has been deleted (but whose embedding
    //     is enqueued for deletion). Client should expect such a scenario, but
    //     all they have to do is just ignore such embeddings.
    //
    // 2.  Other unknown cases: Even if somehow we end up with an embedding for
    //     a existent file which we don't have locally, it is fine because the
    //     current client will just regenerate the embedding if the file really
    //     exists and gets locally found later. There would be a bit of
    //     duplicate work, but that's fine as long as there isn't a systematic
    //     scenario where this happens.
    const localFilesByID = new Map(localFiles.map((f) => [f.id, f]));

    let didPull = false;
    let sinceTime = await embeddingSyncTime(model);
    // TODO: eslint has fixed this spurious warning, but we're not on the latest
    // version yet, so add a disable.
    // https://github.com/eslint/eslint/pull/18286
    /* eslint-disable no-constant-condition */
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    while (true) {
        const remoteEmbeddings = await getEmbeddingsDiff(model, sinceTime);
        if (remoteEmbeddings.length == 0) break;
        let count = 0;
        for (const remoteEmbedding of remoteEmbeddings) {
            sinceTime = Math.max(sinceTime, remoteEmbedding.updatedAt);
            try {
                const file = localFilesByID.get(remoteEmbedding.fileID);
                if (!file) continue;
                await save(
                    await decryptFileMetadataString(
                        remoteEmbedding.encryptedEmbedding,
                        remoteEmbedding.decryptionHeader,
                        file.key,
                    ),
                );
                didPull = true;
                count++;
            } catch (e) {
                log.warn(`Ignoring unparseable ${model} embedding`, e);
            }
        }
        await saveEmbeddingSyncTime(sinceTime, model);
        log.info(`Fetched ${count} ${model} embeddings`);
    }
    return didPull;
};

/**
 * The updatedAt of the most recent {@link RemoteEmbedding} for {@link model}
 * we've retrieved from remote.
 *
 * Returns 0 if there is no such embedding.
 *
 * This value is persisted to local storage. To update it, use
 * {@link saveEmbeddingSyncTime}.
 */
const embeddingSyncTime = async (model: EmbeddingModel) =>
    parseInt((await getKV("embeddingSyncTime:" + model)) ?? "0");

/** Sibling of {@link embeddingSyncTime}. */
const saveEmbeddingSyncTime = async (t: number, model: EmbeddingModel) =>
    setKV("embeddingSyncTime:" + model, `${t}`);

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
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z.object({ diff: z.array(RemoteEmbedding) }).parse(await res.json())
        .diff;
};

/**
 * Upload an embedding to remote.
 *
 * This function will save or update the given embedding as the latest embedding
 * associated with the given {@link enteFile} for {@link model}.
 *
 * @param enteFile {@link EnteFile} to which this embedding relates to.
 *
 * @param model The {@link EmbeddingModel} which we are uploading.
 *
 * @param embedding The binary data the embedding. The exact contents of the
 * embedding are {@link model} specific.
 */
const putEmbedding = async (
    enteFile: EnteFile,
    model: EmbeddingModel,
    embedding: Uint8Array,
) => {
    const { encryptedMetadataB64, decryptionHeaderB64 } =
        await encryptFileMetadata(embedding, enteFile.key);

    const res = await fetch(await apiURL("/embeddings"), {
        method: "PUT",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({
            fileID: enteFile.id,
            encryptedEmbedding: encryptedMetadataB64,
            decryptionHeader: decryptionHeaderB64,
            model,
        }),
    });
    ensureOk(res);
};

/**
 * Upload an embedding to remote.
 *
 * This function will save or update the given embedding as the latest embedding
 * associated with the given {@link enteFile} for {@link model}.
 *
 * @param enteFile {@link EnteFile} to which this embedding relates to.
 *
 * @param model The {@link EmbeddingModel} which we are uploading.
 *
 * @param embedding String representation of the embedding. The exact contents
 * of the embedding are model specific (usually this is the JSON string).
 */
const putEmbeddingString = async (
    enteFile: EnteFile,
    model: EmbeddingModel,
    embedding: string,
) => putEmbedding(enteFile, model, new TextEncoder().encode(embedding));

// MARK: - Combined

/**
 * Update the combined derived data stored for given {@link enteFile} on remote.
 * This allows other clients to directly pull the derived data instead of
 * needing to re-index.
 *
 * The data on remote will be replaced unconditionally, and it is up to the
 * client (us) to ensure that we preserve the parts of the pre-existing derived
 * data (if any) that we did not understand or touch.
 */
export const putDerivedData = async (
    enteFile: EnteFile,
    remoteFaceIndex: RemoteFaceIndex,
    clipIndex: CLIPIndex,
) => {
    const combined = {
        face: remoteFaceIndex,
        clip: clipIndex,
    };
    log.debug(() => ["Uploading derived data", combined]);

    return putEmbedding(
        enteFile,
        "combined",
        await gzip(JSON.stringify(combined)),
    );
};

/**
 * Compress the given {@link string} using "gzip" and return the resultant
 * bytes.
 *
 * This is syntactic sugar to deal with the string/blob/stream/bytes
 * conversions, but it should not be taken as an abstraction layer. If your code
 * can directly use a ReadableStream, then then data -> stream -> data round
 * trip is unnecessary.
 */
const gzip = async (string: string) => {
    const compressedStream = new Blob([string])
        .stream()
        // This code only runs on the desktop app currently, so we can rely on
        // the existence of the CompressionStream API.
        .pipeThrough(new CompressionStream("gzip"));
    return new Uint8Array(await new Response(compressedStream).arrayBuffer());
};

// MARK: - Face

/**
 * Fetch new or updated face embeddings from remote and save them locally.
 *
 * It takes no parameters since it saves the last sync time in local storage.
 *
 * This function should be called only after we have synced files with remote.
 * See: [Note: Ignoring embeddings for unknown files].
 *
 * @returns true if at least one embedding was pulled, false otherwise.
 */
export const pullFaceEmbeddings = () =>
    pullEmbeddings("file-ml-clip-face", (jsonString: string) =>
        // eslint-disable-next-line @typescript-eslint/prefer-ts-expect-error, @typescript-eslint/ban-ts-comment
        // @ts-ignore TODO: There is no error here, but this file is imported by
        // one of our packages that doesn't have strict mode enabled yet,
        // causing a spurious error to be emitted in that context.
        saveFaceIndexIfNewer(FaceIndex.parse(JSON.parse(jsonString))),
    );

/**
 * Save the given {@link faceIndex} locally if it is newer than the one we have.
 *
 * This is a variant of {@link saveFaceIndex} that performs version checking as
 * described in [Note: Handling versioning of embeddings].
 */
const saveFaceIndexIfNewer = async (index: FaceIndex) => {
    const version = index.faceEmbedding.version;
    if (version < faceIndexingVersion) {
        log.info(
            `Ignoring remote face index with version ${version} older than what our indexer can produce (${faceIndexingVersion})`,
        );
        return;
    }
    return saveFaceIndex(index);
};

/**
 * Zod schemas for the {@link RemoteFaceIndex} type.
 *
 * [Note: Duplicated Zod schema and TypeScript type]
 *
 * Usually we define a Zod schema, and then infer the corresponding TypeScript
 * type for it using `z.infer`. This works great except that the docstrings
 * don't show up: Docstrings get added to the Zod schema, but usually the code
 * using the parsed data will reference the TypeScript type, and the docstrings
 * added to the fields in the Zod schema won't show up.
 *
 * We usually live with this infelicity since the alternative is code
 * duplication: Defining a TypeScript type (putting the docstrings therein)
 * _and_ also a corresponding Zod schema. The duplication is needed because it
 * is not possible to go the other way (TypeScript type => Zod schema).
 *
 * However, in some cases having when the TypeScript type under consideration is
 * used pervasively in code, having a standalone TypeScript type with attached
 * docstrings is worth the code duplication.
 *
 * Note that this'll just be syntactic duplication - if the two definitions get
 * out of sync in the shape of the types they represent, the TypeScript compiler
 * will flag it for us.
 */
const RemoteFaceIndex = z.object({
    version: z.number(),
    client: z.string(),
    faces: z.array(
        z.object({
            faceID: z.string(),
            detection: z.object({
                box: z.object({
                    x: z.number(),
                    y: z.number(),
                    width: z.number(),
                    height: z.number(),
                }),
                landmarks: z.array(
                    z.object({
                        x: z.number(),
                        y: z.number(),
                    }),
                ),
            }),
            score: z.number(),
            blur: z.number(),
            embedding: z.array(z.number()),
        }),
    ),
});

/**
 * Save the face index for the given {@link enteFile} on remote so that other
 * clients can directly pull it instead of needing to reindex.
 */
export const putFaceIndex = async (enteFile: EnteFile, faceIndex: FaceIndex) =>
    putEmbeddingString(
        enteFile,
        "file-ml-clip-face",
        JSON.stringify(faceIndex),
    );

// MARK: - CLIP

/**
 * Fetch new or updated CLIP embeddings from remote and save them locally.
 *
 * See {@link pullFaceEmbeddings} for a sibling function with more comprehensive
 * documentation.
 *
 * @returns true if at least one embedding was pulled, false otherwise.
 */
export const pullCLIPEmbeddings = () =>
    pullEmbeddings("onnx-clip", (jsonString: string) =>
        // eslint-disable-next-line @typescript-eslint/prefer-ts-expect-error, @typescript-eslint/ban-ts-comment
        // @ts-ignore TODO: There is no error here, but this file is imported by
        // one of our packages that doesn't have strict mode enabled yet,
        // causing a spurious error to be emitted in that context.
        saveCLIPIndexIfNewer(CLIPIndex.parse(JSON.parse(jsonString))),
    );

/**
 * Save the given {@link clipIndex} locally if it is newer than the one we have.
 *
 * This is a variant of {@link saveCLIPIndex} that performs version checking as
 * described in [Note: Handling versioning of embeddings].
 */
const saveCLIPIndexIfNewer = async (index: CLIPIndex) => {
    const version = index.version;
    if (version < clipIndexingVersion) {
        log.info(
            `Ignoring remote CLIP index with version ${version} older than what our indexer can produce (${clipIndexingVersion})`,
        );
        return;
    }
    return saveCLIPIndex(index);
};

/**
 * Zod schemas for the {@link CLIPIndex} types.
 *
 * See: [Note: Duplicated Zod schema and TypeScript type]
 */
const CLIPIndex = z
    .object({
        fileID: z.number(),
        version: z.number(),
        client: z.string(),
        embedding: z.array(z.number()),
    })
    // Retain fields we might not (currently) understand.
    .passthrough();

/**
 * Save the CLIP index for the given {@link enteFile} on remote so that other
 * clients can directly pull it instead of needing to reindex.
 */
export const putCLIPIndex = async (enteFile: EnteFile, clipIndex: CLIPIndex) =>
    putEmbeddingString(enteFile, "onnx-clip", JSON.stringify(clipIndex));
