import bs58 from "bs58";
import { fromB64, fromHex, toB64 } from "ente-base/crypto";

/**
 * Add the collection key as the hash to the given URL.
 *
 * The hash fragment is a client side component and is not accessible to remote
 * servers. The collection key is base-58 encoded and set as the hash in public
 * URLs of shared albums.
 *
 * Use {@link extractCollectionKeyFromShareURL} to get back the collection key.

 * @param url The base URL for the public album.

 * @param collectionKey The base-64 encoded string representation of the
 * collection key for the public album.
 *
 * @returns A URL that includes the base-58 encoded collection key as the hash
 * fragment.
 */
export const appendCollectionKeyToShareURL = async (
    url: string,
    collectionKey: string,
) => {
    const sharableURL = new URL(url);

    const bytes = await fromB64(collectionKey);
    sharableURL.hash = bs58.encode(bytes);
    return sharableURL.href;
};

/**
 * Extract the collection key from a public URL.
 *
 * This is the inverse of {@link appendCollectionKeyToShareURL}, returning the
 * base64 string representation of the collection key.
 *
 *     collection key (bytes)
 *       => appendCollectionKeytoShareURL (base 64 => base 58)
 *       => URL hash => extractCollectionKeyBytesFromShareURL (base 58 => base 64)
 *       => collection key (bytes).
 */
export const extractCollectionKeyFromShareURL = async (url: URL) => {
    const ck = url.hash.slice(1);
    return ck.length < 50 ? await toB64(bs58.decode(ck)) : await fromHex(ck);
};
