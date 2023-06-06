import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import {
    FileMagicMetadata,
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

export async function updateMagicMetadata(
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
    // copies the existing magic metadata properties of the files and updates the visibility value
    // The expected behavior while updating magic metadata is to let the existing property as it is and update/add the property you want
    const magicMetadataProps: FileMagicMetadataProps = {
        ...originalMagicMetadata.data,
        ...magicMetadataUpdates,
    };

    const nonEmptyMagicMetadataProps = Object.fromEntries(
        Object.entries(magicMetadataProps).filter(
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            ([_, v]) => v !== null && v !== undefined
        )
    );

    let pubMagicMetadata: FileMagicMetadata;
    if (Object.values(nonEmptyMagicMetadataProps)?.length > 0) {
        pubMagicMetadata = {
            ...originalMagicMetadata,
            data: nonEmptyMagicMetadataProps,
            count: Object.keys(nonEmptyMagicMetadataProps).length,
        };
    }
    return pubMagicMetadata;
}
