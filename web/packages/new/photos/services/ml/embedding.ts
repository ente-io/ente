import type { EnteFile } from "@/new/photos/types/file";
import {
    decryptFileMetadata,
    encryptFileMetadata,
} from "@/new/shared/crypto/ente";
import { authenticatedRequestHeaders, ensureOk } from "@/next/http";
import log from "@/next/log";
import { apiURL } from "@/next/origins";
import { nullToUndefined } from "@/utils/transform";
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
 */
// TODO-ML: Fix name to "combined" before release
type EmbeddingModel = "onnx-clip" /* Combined format */;

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

export type RawRemoteDerivedData = Record<string, unknown>;

export type ParsedRemoteDerivedData = Partial<{
    face: RemoteFaceIndex;
    clip: RemoteCLIPIndex;
}>;

/**
 * The decrypted payload of a {@link RemoteEmbedding} for the "combined"
 * {@link EmbeddingModel}.
 *
 * [Note: Preserve unknown derived data fields]
 *
 * The remote derived data can contain arbitrary key at the top level apart from
 * the ones that the current client knows about. We need to preserve these
 * verbatim when we use {@link putDerivedData}.
 *
 * Thus we return two separate results from {@link fetchDerivedData}:
 *
 * -   {@link RawRemoteDerivedData}: The original, unmodified JSON.
 *
 * -   {@link ParsedRemoteDerivedData}: The particular fields that the current
 *     client knows about, parsed according to their expected structure.
 *
 * When integrating this information into our local state, we use the parsed
 * version. And if we need to update the state on remote (e.g. if the current
 * client notices an embedding type that was missing), then we use the original
 * JSON as the base.
 */
export interface RemoteDerivedData {
    raw: RawRemoteDerivedData;
    parsed: ParsedRemoteDerivedData | undefined;
}

/**
 * Zod schema for the {@link RemoteFaceIndex} type.
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
 * Zod schema for the {@link RemoteCLIPIndex} type.
 *
 * See: [Note: Duplicated Zod schema and TypeScript type]
 */
const RemoteCLIPIndex = z.object({
    version: z.number(),
    client: z.string(),
    embedding: z.array(z.number()),
});

/**
 * Zod schema for the {@link RawRemoteDerivedData} type.
 */
const RawRemoteDerivedData = z.object({}).passthrough();

/**
 * Zod schema for the {@link ParsedRemoteDerivedData} type.
 */
const ParsedRemoteDerivedData = z.object({
    face: RemoteFaceIndex.nullish().transform(nullToUndefined),
    clip: RemoteCLIPIndex.nullish().transform(nullToUndefined),
});

/**
 * Fetch derived data for the given files from remote.
 *
 * @param filesByID A map containing the files whose derived data we want to
 * fetch. Each entry is keyed the the file's ID, and the value is the file.
 *
 * @returns a map containing the (decrypted) derived data for each file for
 * which remote returned the corresponding embedding. Each entry in the map is
 * keyed by file's ID, and each value is a {@link RemoteDerivedData} that
 * contains both the original JSON, and parsed representation of embeddings that
 * we know about.
 */
export const fetchDerivedData = async (
    filesByID: Map<number, EnteFile>,
): Promise<Map<number, RemoteDerivedData>> => {
    // TODO-ML: Fix name to "combined" before release
    const remoteEmbeddings = await fetchEmbeddings("onnx-clip", [
        ...filesByID.keys(),
    ]);

    const result = new Map<number, RemoteDerivedData>();
    for (const remoteEmbedding of remoteEmbeddings) {
        const { fileID } = remoteEmbedding;
        const file = filesByID.get(fileID);
        if (!file) {
            log.warn(`Ignoring derived data for unknown fileID ${fileID}`);
            continue;
        }

        try {
            const decryptedBytes = await decryptFileMetadata(
                remoteEmbedding.encryptedEmbedding,
                remoteEmbedding.decryptionHeader,
                file.key,
            );
            const jsonString = await gunzip(decryptedBytes);
            result.set(fileID, remoteDerivedDataFromJSONString(jsonString));
        } catch (e) {
            // This shouldn't happen. Likely some client has uploaded a
            // corrupted embedding. Ignore it so that it gets reindexed and
            // uploaded correctly again.
            log.warn(`Ignoring unparseable embedding for ${fileID}`, e);
        }
    }
    log.debug(() => `Fetched ${result.size} combined embeddings`);
    return result;
};

const remoteDerivedDataFromJSONString = (jsonString: string) => {
    const raw = RawRemoteDerivedData.parse(JSON.parse(jsonString));
    const parseResult = ParsedRemoteDerivedData.safeParse(raw);
    // This code is included in apps/photos, which currently does not have the
    // TypeScript strict mode enabled, which causes a spurious tsc failure.
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment, @typescript-eslint/prefer-ts-expect-error
    // @ts-ignore
    const parsed = parseResult.success
        ? (parseResult.data as ParsedRemoteDerivedData)
        : undefined;
    return { raw, parsed };
};

/**
 * Fetch {@link model} embeddings for the given list of files.
 *
 * @param model The {@link EmbeddingModel} which we want.
 *
 * @param fileIDs The ids of the files for which we want the embeddings.
 *
 * @returns a list of {@link RemoteEmbedding} for the files which had embeddings
 * (and thatt remote was able to successfully retrieve). The order of this list
 * is arbitrary, and the caller should use the {@link fileID} present within the
 * {@link RemoteEmbedding} to associate an item in the result back to a file
 * instead of relying on the order or count of items in the result.
 */
const fetchEmbeddings = async (
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
    return z
        .object({ embeddings: z.array(RemoteEmbedding) })
        .parse(await res.json()).embeddings;
};

/**
 * Update the derived data stored for given {@link enteFile} on remote.
 *
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
    derivedData: RawRemoteDerivedData,
) =>
    // TODO-ML: Fix name to "combined" before release
    putEmbedding(enteFile, "onnx-clip", await gzip(JSON.stringify(derivedData)));

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
