import { getEndpoint } from "utils/common/apiUtil";
import { getData, LS_KEYS } from "utils/storage/localStorage";
import { collection } from "./fileService";
import HTTPService from "./HTTPService";
import * as Comlink from 'comlink';


const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));
const ENDPOINT = getEndpoint();


const getCollectionKey = async (collection: collection, key: Uint8Array) => {
    const worker = await new CryptoWorker();
    const userID = getData(LS_KEYS.USER).id;
    var decryptedKey;
    if (collection.owner.id == userID) {
        decryptedKey = await worker.decrypt(
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(collection.keyDecryptionNonce),
            key
        );
    } else {
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const secretKey = await worker.decrypt(
            await worker.fromB64(keyAttributes.encryptedSecretKey),
            await worker.fromB64(keyAttributes.secretKeyDecryptionNonce),
            key
        );
        decryptedKey = await worker.boxSealOpen(
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(keyAttributes.publicKey),
            secretKey
        );
    }
    return {
        ...collection,
        key: decryptedKey,
    };
};

const getCollections = async (
    token: string,
    sinceTime: string,
    key: Uint8Array
): Promise<collection[]> => {
    const resp = await HTTPService.get(`${ENDPOINT}/collections`, {
        token: token,
        sinceTime: sinceTime,
    });

    const promises: Promise<collection>[] = resp.data.collections.map(
        (collection: collection) => getCollectionKey(collection, key)
    );
    return await Promise.all(promises);
};

export const fetchCollections = async (token: string, key: string) => {
    const worker = await new CryptoWorker();
    return getCollections(token, '0', await worker.fromB64(key));
};
