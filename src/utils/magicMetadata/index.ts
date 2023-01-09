import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import {
    FileMagicMetadataProps,
    MagicMetadataCore,
    VISIBILITY_STATE,
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

export async function updateMagicMetadataProps(
    originalMagicMetadata: MagicMetadataCore,
    decryptionKey: string,
    magicMetadataUpdates: Record<string, any>
) {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();

    if (!originalMagicMetadata) {
        throw Error('invalid originalMagicMetadata ');
    }
    if (typeof originalMagicMetadata.data === 'string') {
        originalMagicMetadata.data = (await cryptoWorker.decryptMetadata(
            originalMagicMetadata.data,
            originalMagicMetadata.header,
            decryptionKey
        )) as FileMagicMetadataProps;
    }
    if (magicMetadataUpdates) {
        // copies the existing magic metadata properties of the files and updates the visibility value
        // The expected behavior while updating magic metadata is to let the existing property as it is and update/add the property you want
        const magicMetadataProps: FileMagicMetadataProps = {
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
