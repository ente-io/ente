import type { EnteFile } from "@/new/photos/types/file";
import {
    decryptFileMetadataString,
    encryptFileMetadata,
} from "@/new/shared/crypto/ente";
import { authenticatedRequestHeaders, ensureOk } from "@/next/http";
import log from "@/next/log";
import { apiURL } from "@/next/origins";
import { z } from "zod";
import { type RemoteCLIPIndex } from "./clip";
import { type RemoteFaceIndex } from "./face";

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
});

type RemoteEmbedding = z.infer<typeof RemoteEmbedding>;

/**
 * The decrypted payload of a {@link RemoteEmbedding} for the "combined"
 * {@link EmbeddingModel}.
 *
 * [Note: Preserve unknown derived data fields]
 *
 * There is one entry for each of the embedding types that the current client
 * knows about. However, there might be other fields apart from the known ones
 * at the top level, and we need to ensure that we preserve them verbatim when
 * trying use {@link putDerivedData} with an {@link RemoteDerivedData} obtained
 * from remote as the base, with locally indexed additions.
 */
export type RemoteDerivedData = Record<string, unknown> & {
    face: RemoteFaceIndex;
    clip: RemoteCLIPIndex;
};

/**
 * Fetch derived data for the given files from remote.
 */
export const getDerivedData = async (fileIDs: string[]) => {
    const remoteEmbeddings = await getEmbeddings("combined", fileIDs);
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
    log.debug(() => `Fetched ${count} combined embeddings`);
};

/**
 * GET the {@link model} embeddings for the given list of files.
 *
 * @param model The {@link EmbeddingModel} which we want.
 *
 * @param fileIDs The ids of the files for which we want the embeddings.
 *
 * @returns an array of {@link RemoteEmbedding}. The returned array is limited
 * to a maximum count of {@link diffLimit}.
 *
 * > See [Note: Limit of returned items in /diff requests].
 */
const getEmbeddings = async (
    model: EmbeddingModel,
    fileIDs: number[],
): Promise<RemoteEmbedding[]> => {
    const res = await fetch(await apiURL("/embeddings/files"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({
            model,
            fileIDs,
        }),
    });
    ensureOk(res);
    return z.object({ diff: z.array(RemoteEmbedding) }).parse(await res.json())
        .diff;
};

/**
 * Update the combined derived data stored for given {@link enteFile} on remote.
 * This allows other clients to directly pull the derived data instead of
 * needing to re-index.
 *
 * The data on remote will be replaced unconditionally, and it is up to the
 * client (us) to ensure that we preserve the parts of the pre-existing derived
 * data (if any) that we did not understand or touch.
 *
 * See: [Note: Preserve unknown derived data fields].
 */
export const putDerivedData = async (
    enteFile: EnteFile,
    derivedData: RemoteDerivedData,
) =>
    putEmbedding(enteFile, "combined", await gzip(JSON.stringify(derivedData)));

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
    width: z.number(),
    height: z.number(),
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
 * Zod schemas for the {@link RemoteCLIPIndex} types.
 *
 * See: [Note: Duplicated Zod schema and TypeScript type]
 */
const RemoteCLIPIndex = z.object({
    version: z.number(),
    client: z.string(),
    embedding: z.array(z.number()),
});

// MARK: - GZIP

/**
 * Compress the given {@link string} using "gzip" and return the resultant
 * bytes. See {@link gunzip} for the reverse operation.
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
        // the existence of new web features the CompressionStream APIs.
        .pipeThrough(new CompressionStream("gzip"));
    return new Uint8Array(await new Response(compressedStream).arrayBuffer());
};

/**
 * Decompress the given "gzip" compressed {@link data} and return the resultant
 * string. See {@link gzip} for the reverse operation.
 */
const gunzip = async (data: Uint8Array) => {
    const decompressedStream = new Blob([data])
        .stream()
        // This code only runs on the desktop app currently, so we can rely on
        // the existence of new web features the CompressionStream APIs.
        .pipeThrough(new DecompressionStream("gzip"));
    return new Response(decompressedStream).text();
};
