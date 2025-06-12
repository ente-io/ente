import { decryptMetadataJSON, encryptMetadataJSON } from "ente-base/crypto";
import type { BytesOrB64 } from "ente-base/crypto/types";
import { z } from "zod/v4";

/**
 * Zod schema of the mutable metadatum objects that we send to or receive from
 * remote. It is effectively an envelope of the encrypted metadata contents with
 * some bookkeeping information attached.
 *
 * See {@link RemoteMagicMetadata} for the corresponding type. Since this module
 * exports both the Zod schema and the TypeScript type, to avoid confusion the
 * schema is suffixed by "Schema".
 */
export const RemoteMagicMetadataSchema = z.object({
    version: z.number(),
    count: z.number(),
    data: z.string(),
    header: z.string(),
});

/**
 * Any of the mutable metadata fields, as represented by remote.
 *
 * See: [Note: Metadatum]
 *
 * This is the encrypted magic metadata that we send to and receive from remote.
 * It contains the encrypted contents, and a version + count of fields that help
 * ensure that clients do not overwrite updates with stale objects.
 *
 * When decrypt these into specific {@link MagicMetadata} instantiations before
 * using and storing them on the client.
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
     * The encryption will happen using the "key" of the object whose magic
     * metadata field this is. For example, if this is the
     * {@link pubMagicMetadata} of an {@link EnteFile}, then the file's key will
     * be used for encryption.
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
 * from the envelope ({@link RemoteMagicMetadata}), while the encrypted contents
 * ({@link data} and {@link header}) are decrypted into a JSON object.
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
export interface MagicMetadata<T> {
    version: number;
    count: number;
    data: T;
}

/**
 * Encrypt the provided magic metadata into a form that can be used in
 * communication with remote, updating the count if needed.
 *
 * @param magicMetadata The decrypted {@link MagicMetadata} that is being used
 * by the client.
 *
 * As a usability convenience, this function allows passing `undefined` as the
 * {@link magicMetadata}. In such a case, it will return `undefined` too.
 *
 * It is okay for the count in the envelope to be out of sync with the count in
 * the actual JSON object contents, this function will update the envelope count
 * with the number of entries in the JSON object.
 *
 * Any entries in {@link magicMetadata} that are `null` or `undefined` are
 * discarded before obtaining the final object that will be encrypted (and whose
 * count will be used).
 *
 * @param key The key to use for encrypting the {@link data} contents of
 * {@link magicMetadata}.
 *
 * The specific key used depends on the object whose metadata this is. For
 * example, if this were the {@link pubMagicMetadata} associated with an
 * {@link EnteFile}, then this would be the file's key.
 *
 * @returns a {@link RemoteMagicMetadata} object that contains the encrypted
 * contents of the {@link data} present in the provided {@link magicMetadata}.
 * The {@link version} is copied over from the provided {@link magicMetadata},
 * while the {@link count} is obtained from the number of entries in the JSON
 * object (the {@link data} property of {@link magicMetadata}).
 *
 */
export const encryptMagicMetadata = async <T>(
    magicMetadata: MagicMetadata<T> | undefined,
    key: BytesOrB64,
): Promise<RemoteMagicMetadata | undefined> => {
    if (!magicMetadata) return undefined;

    // Discard any entries that are `null` or `undefined`.
    const jsonObject = Object.fromEntries(
        Object.entries(magicMetadata.data ?? {}).filter(
            ([, v]) => v !== null && v !== undefined,
        ),
    );

    const version = magicMetadata.version;
    const count = Object.keys(jsonObject).length;

    const { encryptedData: data, decryptionHeader: header } =
        await encryptMetadataJSON(jsonObject, key);

    return { version, count, data, header };
};

/**
 * Decrypt the magic metadata received from remote into an object suitable for
 * use and persistence by us (the client).
 *
 * This is meant as the inverse of {@link encryptMagicMetadata}, see that
 * function's documentation for more information.
 */
export const decryptMagicMetadata = async (
    remoteMagicMetadata: RemoteMagicMetadata | undefined,
    key: BytesOrB64,
): Promise<MagicMetadata<unknown> | undefined> => {
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
