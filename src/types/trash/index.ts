import { EnteFile } from 'types/file';

export interface TrashItem {
    file: EnteFile;
    isDeleted: boolean;
    isRestored: boolean;
    deleteBy: number;
    createdAt: number;
    updatedAt: number;
}
export type Trash = TrashItem[];
