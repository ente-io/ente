import { decryptFileEmbedding } from "@/base/crypto/ente";
import log from "@/base/log";
import type { EnteFile } from "@/new/photos/types/file";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import { fetchFileData, putFileData } from "../file-data";
import { gunzip, gzip } from "../gzip";
import { type RemoteCLIPIndex } from "./clip";
import { type RemoteFaceIndex } from "./face";

export type RawRemoteMLData = Record<string, unknown>;

export type ParsedRemoteMLData = Partial<{
    face: RemoteFaceIndex;
    clip: RemoteCLIPIndex;
}>;

/**
 * The decrypted payload of a {@link RemoteFileData} for the "derived"
 * {@link FileDataType}.
 *
 * [Note: Preserve unknown derived data fields]
 *
 * The remote derived data can contain arbitrary key at the top level apart from
 * the ones that the current client knows about. We need to preserve these
 * verbatim when we use {@link putMLData}.
 *
 * Thus we return two separate results from {@link fetchMLData}:
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
export interface RemoteMLData {
    raw: RawRemoteMLData;
    parsed: ParsedRemoteMLData | undefined;
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
 * keyed by file's ID, and each value is a {@link RemoteMLData} that
 * contains both the original JSON, and parsed representation of embeddings that
 * we know about.
 */
export const fetchMLData = async (
    filesByID: Map<number, EnteFile>,
): Promise<Map<number, RemoteMLData>> => {
    const remoteEmbeddings = await fetchFileData("mldata", [
        ...filesByID.keys(),
    ]);

    const result = new Map<number, RemoteMLData>();
    for (const remoteEmbedding of remoteEmbeddings) {
        const { fileID } = remoteEmbedding;
        const file = filesByID.get(fileID);
        if (!file) {
            log.warn(`Ignoring derived data for unknown file id ${fileID}`);
            continue;
        }

        try {
            const decryptedBytes = await decryptFileEmbedding({
                encryptedDataB64: remoteEmbedding.encryptedData,
                decryptionHeaderB64: remoteEmbedding.decryptionHeader,
                keyB64: file.key,
            });
            const jsonString = await gunzip(decryptedBytes);
            result.set(fileID, remoteMLDataFromJSONString(jsonString));
        } catch (e) {
            // This shouldn't happen. Best guess is that some client has
            // uploaded a corrupted embedding. Ignore it so that it gets
            // reindexed and uploaded correctly again.
            log.warn(`Ignoring unparseable embedding for file id ${fileID}`, e);
        }
    }
    log.debug(() => `Fetched derived data for ${result.size} files`);
    return result;
};

const remoteMLDataFromJSONString = (jsonString: string) => {
    const raw = RawRemoteDerivedData.parse(JSON.parse(jsonString));
    const parseResult = ParsedRemoteDerivedData.safeParse(raw);
    // This code is included in apps/photos, which currently does not have the
    // TypeScript strict mode enabled, which causes a spurious tsc failure.
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment, @typescript-eslint/prefer-ts-expect-error
    // @ts-ignore
    const parsed = parseResult.success
        ? (parseResult.data as ParsedRemoteMLData)
        : undefined;
    return { raw, parsed };
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
export const putMLData = async (
    enteFile: EnteFile,
    derivedData: RawRemoteMLData,
) => putFileData(enteFile, "mldata", await gzip(JSON.stringify(derivedData)));
