import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { VISIBILITY_STATE } from 'types/magicMetadata';

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
