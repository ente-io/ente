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
