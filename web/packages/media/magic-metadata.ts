import { decryptMetadataJSON, encryptMetadataJSON } from "ente-base/crypto";
import { z } from "zod/v4";

/**
 * Zod schema of the mutable metadatum objects that we send to or receive from
 * remote. Even though it is named so, it is not the metadata itself, but an
 * envelope containing the encrypted metadata contents with some bookkeeping
 * information attached.
 *
 * See {@link RemoteMagicMetadata} for the corresponding type.
 *
 * [Note: Schema suffix for exported Zod schemas]
 *
 * Since this module exports both the Zod schema and the TypeScript type, to
 * avoid confusion the schema is suffixed by "Schema".
 *
 * This is a general pattern we follow in all cases where we need to export the
 * Zod schema so other modules can compose schema definitions. Such exports are
 * meant to be exceptions though; usually the schema should be internal to the
 * module (and so can have the same name as the TypeScript type without the need
 * for a disambiguating suffix).
 */
export const RemoteMagicMetadataSchema = z.object({
    version: z.number(),
    count: z.number(),
    data: z.string(),
    header: z.string(),
});

/**
 * The type of the mutable metadata fields, as represented by remote.
 *
 * See: [Note: Metadatum]
 *
 * This is the magic metadata envelope that we send to and receive from remote.
 * It contains the encrypted contents, and a version + count of fields that help
 * ensure that clients do not overwrite updates with stale objects.
 *
 * When decrypt these into specific local {@link MagicMetadataEnvelope}
 * instantiations before using and storing them on the client.
 *
 * See {@link RemoteMagicMetadataSchema} for the corresponding Zod schema. The
 * same structure is used to store the metadata for various kinds of objects
 * (files, collections), so this module exports both the TypeScript type and
 * also the Zod schema so that other modules can compose schema definitions.
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
     * The number of keys with non-null (and non-undefined) values in the
     * encrypted JSON object that the encrypted metadata blob contains.
     *
     * During edits and updates, this number should be greater than or equal to
     * the previous version.
     *
     * > Clients are expected to retain the magic metadata verbatim so that they
     * > don't accidentally overwrite fields that they might not understand.
     * >
     * > See: [Note: Use looseObject for metadata Zod schemas]
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
 * from the remote envelope ({@link RemoteMagicMetadata}), while the encrypted
 * contents ({@link data} and {@link header}) are decrypted into a JSON object.
 *
 * Since different types of magic metadata fields have different JSON contents,
 * so this decrypted JSON object is parameterized as `T` in this generic type.
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
export interface MagicMetadataEnvelope<T = unknown> {
    version: number;
    count: number;
    /**
     * The "metadata" itself.
     *
     * This is expected to be a JSON object, whose exact schema depends on the
     * field for which this envelope is being used.
     */
    data: T;
}

/**
 * Encrypt the provided magic metadata envelope into a form that can be used in
 * communication with remote, updating the count if needed.
 *
 * @param envelope The decrypted {@link MagicMetadataEnvelope} that
 * is being used by the client.
 *
 * As a usability convenience, this function allows passing `undefined` as the
 * {@link envelope}. In such cases, it will return `undefined` too.
 *
 * It is okay for the count in the envelope to be out of sync with the count in
 * the actual JSON object contents, this function will update the envelope count
 * with the number of entries in the JSON object.
 *
 * Any entries in {@link envelope} that are `null` or `undefined`
 * are discarded before obtaining the final object that will be encrypted (and
 * whose count will be used).
 *
 * @param key The base64 encoded key to use for encrypting the {@link data}
 * contents of {@link envelope}.
 *
 * The specific key used depends on the object whose metadata this is. For
 * example, if this were the {@link pubMagicMetadata} associated with an
 * {@link EnteFile}, then this would be the file's key.
 *
 * @returns a {@link RemoteMagicMetadata} object that contains the encrypted
 * contents of the {@link data} present in the provided
 * {@link envelope}. The {@link version} is copied over from the
 * provided {@link envelope}, while the {@link count} is obtained
 * from the number of entries in the trimmed JSON object obtained from the
 * {@link data} property of {@link envelope}.
 *
 */
export const encryptMagicMetadata = async (
    envelope: MagicMetadataEnvelope | undefined,
    key: string,
): Promise<RemoteMagicMetadata | undefined> => {
    if (!envelope) return undefined;

    const { version } = envelope;

    const newEnvelope = createMagicMetadataEnvelope(envelope.data);
    const { count } = newEnvelope;

    const { encryptedData: data, decryptionHeader: header } =
        await encryptMetadataJSON(newEnvelope.data, key);

    return { version, count, data, header };
};

/**
 * A function to wrap an arbitrary JSON object in an envelope expected of
 * various magic metadata fields.
 *
 * A trimmed JSON object is obtained from the provided JSON object by removing
 * any entries whose values is `undefined` or `null`.
 *
 * Then,
 *
 * - The `version` is set to 0.
 * - The `count` is set to the number of entries in the trimmed JSON object.
 * - The `data` is set to the trimmed JSON object.
 *
 * {@link encryptMagicMetadata} internally uses this function to obtain an
 * up-to-date envelope before computing the count and encrypting the contents.
 * This function is also exported for use in places where we don't have an
 * existing envelope, and would like to create one from scratch.
 *
 * @param data The "metadata" JSON object. Since TypeScript does not have a JSON
 * type, this uses the `unknown` type.
 */
export const createMagicMetadataEnvelope = (data: unknown) => {
    // Discard any entries that are `undefined` or `null`.
    const jsonObject = Object.fromEntries(
        Object.entries(data ?? {}).filter(
            ([, v]) => v !== undefined && v !== null,
        ),
    );

    const count = Object.keys(jsonObject).length;

    return { version: 0, count, data: jsonObject };
};

/**
 * Decrypt the magic metadata (envelope) received from remote into an object
 * suitable for use and persistence by the client.
 *
 * This is meant as the inverse of {@link encryptMagicMetadata}, see that
 * function's documentation for more information.
 */
export const decryptMagicMetadata = async (
    remoteMagicMetadata: RemoteMagicMetadata | undefined,
    key: string,
): Promise<MagicMetadataEnvelope | undefined> => {
    if (!remoteMagicMetadata) return undefined;

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
