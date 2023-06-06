import {
    FilePublicMagicMetadataProps,
    FilePublicMagicMetadata,
} from 'types/file';
import { updateMagicMetadata } from 'utils/magicMetadata';

export async function constructPublicMagicMetadata(
    publicMagicMetadataProps: FilePublicMagicMetadataProps
): Promise<FilePublicMagicMetadata> {
    const pubMagicMetadata = await updateMagicMetadata(
        publicMagicMetadataProps
    );
    return pubMagicMetadata;
}
