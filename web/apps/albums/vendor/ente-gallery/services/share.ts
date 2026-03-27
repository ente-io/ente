import bs58 from "bs58";
import { fromHex, toB64 } from "ente-base/crypto";

/**
 * Extract the collection key from a public URL.
 *
 * Public album URLs encode the collection key in the hash as base-58.
 * Legacy links might still carry the older hex encoding.
 */
export const extractCollectionKeyFromShareURL = async (url: URL) => {
    const ck = url.hash.slice(1);
    return ck.length < 50 ? await toB64(bs58.decode(ck)) : await fromHex(ck);
};
