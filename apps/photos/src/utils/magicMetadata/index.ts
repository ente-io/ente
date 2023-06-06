import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import {
    MagicMetadataCore,
    VISIBILITY_STATE,
    getNewMagicMetadata,
} from 'types/magicMetadata';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';

export function IsArchived(item: Collection | EnteFile) {
    if (
        !item ||
        !item.magicMetadata ||
        !item.magicMetadata.data ||
        typeof item.magicMetadata.data === 'string' ||
        typeof item.magicMetadata.data.visibility === 'undefined'
    ) {
        return false;
    }
    return item.magicMetadata.data.visibility === VISIBILITY_STATE.ARCHIVED;
}

export async function updateMagicMetadata<T>(
    magicMetadataUpdates: T,
    originalMagicMetadata?: MagicMetadataCore<T>,
    decryptionKey?: string
): Promise<MagicMetadataCore<T>> {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();

    if (!originalMagicMetadata) {
        originalMagicMetadata = getNewMagicMetadata<T>();
    }

    if (typeof originalMagicMetadata?.data === 'string') {
        originalMagicMetadata.data = (await cryptoWorker.decryptMetadata(
            originalMagicMetadata.data,
            originalMagicMetadata.header,
            decryptionKey
        )) as T;
    }

    if (magicMetadataUpdates) {
        // copies the existing magic metadata properties of the files and updates the visibility value
        // The expected behavior while updating magic metadata is to let the existing property as it is and update/add the property you want
        const magicMetadataProps: T = {
            ...originalMagicMetadata.data,
            ...magicMetadataUpdates,
        };

        return {
            ...originalMagicMetadata,
            data: magicMetadataProps,
            count: Object.keys(magicMetadataProps).length,
        };
    } else {
        return originalMagicMetadata;
    }
}
