import {} from 'types/file';
import {
    NEW_FILE_MAGIC_METADATA,
    FilePublicMagicMetadataProps,
    FilePublicMagicMetadata,
} from 'types/magicMetadata';
import { updateMagicMetadataProps } from 'utils/magicMetadata';

export async function constructPublicMagicMetadata(
    publicMagicMetadataProps: FilePublicMagicMetadataProps
): Promise<FilePublicMagicMetadata> {
    const pubMagicMetadata = await updateMagicMetadataProps(
        NEW_FILE_MAGIC_METADATA,
        null,
        publicMagicMetadataProps
    );
    return pubMagicMetadata;
}
