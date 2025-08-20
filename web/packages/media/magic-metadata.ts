import { decryptMetadataJSON, encryptMetadataJSON } from "ente-base/crypto";
import { nullishToZero } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * Zod schema of the mutable metadatum objects that we send to or receive from
 * remote. It contains an encrypted metadata JSON object with some bookkeeping
 * information attached.
 *
 * See {@link RemoteMagicMetadata} for the corresponding type.
 */
export const RemoteMagicMetadata = z.object({
    version: z.number(),
    count: z.number().nullish().transform(nullishToZero),
    data: z.string(),
    header: z.string(),
});

/**
 * The type of the mutable metadata fields, as represented by remote.
 *
 * See: [Note: Metadatum]
 *
 * This is the magic metadata that we send to and receive from remote. It
 * contains an encrypted JSON object, and a version + count of entries to ensure
 * that clients do not overwrite already applied updates with stale objects.
 *
 * When decrypt these into specific local {@link MagicMetadata} instantiations
 * before using and storing them on the client.
 */
export interface RemoteMagicMetadata {
    /**
     * Monotonically increasing iteration of this metadata object.
     *
     * The version starts at 1. Remote increments this version number each time
     * a client updates the corresponding magic metadata field.
     */
    version: number;
    /**
     * The number of keys with non-nullish (i.e. not null and not undefined)
     * values in the encrypted JSON object that the encrypted metadata blob
     * contains.
     *
     * [Note: Magic metadata data cannot have nullish values]
     *
     * Clients are expected to retain the magic metadata verbatim so that they
     * don't accidentally overwrite fields that they might not understand. See:
     * [Note: Use looseObject for metadata Zod schemas]
     *
     * Remote enforces this by requiring that during edits and updates, this
     * number should be greater than or equal to the previous version.
     *
     * Locally we enforce this in the {@link createMagicMetadata} function
     * (which is used for both creation and updates), which trims off any
     * entries in the data object whose value is `null` or `undefined` before
     * arriving at the final object to use.
     *
     * This has the side effect that metadata entries cannot be deleted by
     * setting their value to nullish. However usually the specific field
     * semantics allow a reset to default behaviour by setting the value of the
     * entry to the corresponding empty primitive (e.g. 0).
     */
    count: number;
    /**
     * The encrypted data.
     *
     * This are the base64 encoded bytes of the encrypted magic metadata JSON
     * object.
     *
     * The encryption will happen using the "key" associated with the object
     * whose magic metadata field this is. For example, if this is the
     * {@link pubMagicMetadata} of an {@link EnteFile}, then the file's key will
     * be used for encryption and decryption.
     */
    data: string;
    /**
     * The base64 encoded decryption header that will be needed for the client
     * for decrypting {@link data}.
     */
    header: string;
}

/**
 * The decrypted form of {@link RemoteMagicMetadata} used and locally persisted
 * by the client.
 *
 * The bookkeeping fields ({@link version} and {@link count}) are copied over
 * from the remote object ({@link RemoteMagicMetadata}), while the encrypted
 * contents ({@link data} and {@link header} of {@link RemoteMagicMetadata}) are
 * decrypted into a JSON object that is stored as {@link data}.
 *
 * Since different types of magic metadata fields are expected to contain
 * different JSON objects as {@link data}, the type is generic, with the generic
 * parameter `T` standing for the type of the JSON object.
 *
 * > Since TypeScript does not currently have a native JSON type, this T doesn't
 * > have other constraints enforced by the type system, but it is meant to be a
 * > JSON object.
 *
 * The word "magic metadata" by itself ambiguous. It refers to both the specific
 * "magicMetadata" fields present in, say, the file and collection objects, and
 * also to the shape of the structure this field shares with other semantically
 * similar fields (e.g. public magic metadata). This type uses it in the second
 * sense - to describe the shape of any of the magic metadata like fields used
 * in various types. See: [Note: Metadatum].
 */
export interface MagicMetadata<T = unknown> {
    version: number;
    count: number;
    /**
     * The "metadata" itself.
     *
     * This is expected to be a JSON object, whose exact schema depends on the
     * magic metadata field in the parent object.
     */
    data: T;
}

/**
 * Encrypt the provided magic metadata into a form that can be used in
 * communication with remote, trimming the JSON object and updating the count.
 *
 * @param magicMetadata The decrypted {@link MagicMetadata} that is being used
 * by the client.
 *
 * Any entries in {@link magicMetadata}'s {@link data} that are `null` or
 * `undefined` are discarded before obtaining the final object that will be
 * encrypted (and whose count will be used).
 *
 * So in particular, it is okay for the count in the {@link magicMetadata} to be
 * out of sync with the count in the `data` JSON object because this function
 * will recompute the count using the trimmed JSON object.
 *
 * @param key The base64 encoded key to use for encrypting the {@link data}
 * contents of {@link magicMetadata}.
 *
 * The specific key used depends on the object whose magic metadata field this
 * is meant for. For example, if this were the {@link pubMagicMetadata}
 * associated with an {@link EnteFile}, then this would be the file's key.
 *
 * @returns a {@link RemoteMagicMetadata} object that contains the encrypted
 * contents of the {@link data} present in the provided {@link magicMetadata}.
 * The {@link version} is copied over from the provided {@link magicMetadata},
 * while the {@link count} is obtained from the number of entries in the trimmed
 * JSON object that was encrypted.
 */
export const encryptMagicMetadata = async (
    magicMetadata: MagicMetadata,
    key: string,
): Promise<RemoteMagicMetadata> => {
    const { version } = magicMetadata;

    const newMM = createMagicMetadata(magicMetadata.data);
    const { count } = newMM;

    const { encryptedData: data, decryptionHeader: header } =
        await encryptMetadataJSON(newMM.data, key);

    return { version, count, data, header };
};

/**
 * A function to wrap an arbitrary JSON object in the {@link MagicMetadata}
 * envelope used for the various magic metadata fields.
 *
 * A trimmed JSON object is obtained from the provided JSON object by removing
 * any entries whose values is nullish (`null` or `undefined`).
 *
 * Then,
 *
 * - The `version` is set to provided value (or 1).
 * - The `count` is set to the number of entries in the trimmed JSON object.
 * - The `data` is set to the trimmed JSON object.
 *
 * {@link encryptMagicMetadata} internally uses this function to obtain an
 * trimmed `data` and its corresponding `count`. This function is also exported
 * for use in places where we just have a JSON object and would like to a new
 * {@link MagicMetadata} object to house it from scratch.
 *
 * @param data A JSON object. Since TypeScript does not have a JSON type, this
 * uses the `unknown` type.
 *
 * @param version An optional version number to use. This is useful when
 * updating existing magic metadata, where the version in the update that we
 * send to remote must match the existing version.
 *
 * If not provided, the 1 is used as the version.
 */
export const createMagicMetadata = (data: unknown, version?: number) => {
    // Discard any entries that with nullish (`null` or `undefined`) values.
    //
    // See: [Note: Magic metadata data cannot have nullish values]
    const jsonObject = Object.fromEntries(
        Object.entries(data ?? {}).filter(
            ([, v]) => v !== null && v !== undefined,
        ),
    );

    const count = Object.keys(jsonObject).length;

    return { version: version ?? 1, count, data: jsonObject };
};

/**
 * Decrypt the magic metadata received from remote into an object suitable for
 * use and persistence by the client.
 *
 * This is meant as the inverse of {@link encryptMagicMetadata}, see that
 * function's documentation for details.
 */
export const decryptMagicMetadata = async (
    remoteMagicMetadata: RemoteMagicMetadata,
    key: string,
): Promise<MagicMetadata> => {
    const {
        version,
        count,
        data: encryptedData,
        header: decryptionHeader,
    } = remoteMagicMetadata;

    const data = await decryptMetadataJSON(
        { encryptedData, decryptionHeader },
        key,
    );

    return { version, count, data };
};
