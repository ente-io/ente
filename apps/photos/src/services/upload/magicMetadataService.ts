import {
    NEW_FILE_MAGIC_METADATA,
    FilePublicMagicMetadataProps,
    FilePublicMagicMetadata,
} from 'types/magicMetadata';
import { updateMagicMetadata } from 'utils/magicMetadata';

export async function constructPublicMagicMetadata(
    publicMagicMetadataProps: FilePublicMagicMetadataProps
): Promise<FilePublicMagicMetadata> {
    const pubMagicMetadata = await updateMagicMetadata(
        NEW_FILE_MAGIC_METADATA,
        null,
        publicMagicMetadataProps
    );
    return pubMagicMetadata;
}
