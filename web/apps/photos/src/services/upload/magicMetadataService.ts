import {
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
} from "types/file";
import {
    getNonEmptyMagicMetadataProps,
    updateMagicMetadata,
} from "utils/magicMetadata";

export async function constructPublicMagicMetadata(
    publicMagicMetadataProps: FilePublicMagicMetadataProps,
): Promise<FilePublicMagicMetadata> {
    const nonEmptyPublicMagicMetadataProps = getNonEmptyMagicMetadataProps(
        publicMagicMetadataProps,
    );

    if (Object.values(nonEmptyPublicMagicMetadataProps)?.length === 0) {
        return null;
    }
    return await updateMagicMetadata(publicMagicMetadataProps);
}
