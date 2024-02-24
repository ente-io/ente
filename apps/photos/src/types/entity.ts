import { Location } from "types/upload";

export enum EntityType {
    LOCATION_TAG = "location",
}

export interface EncryptedEntityKey {
    userID: number;
    encryptedKey: string;
    type: EntityType;
    header: string;
    createdAt: number;
}

export interface EntityKey
    extends Omit<EncryptedEntityKey, "encryptedKey" | "header"> {
    data: string;
}

export interface EncryptedEntity {
    id: string;
    encryptedData: string;
    header: string;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
    userID: number;
}

export interface LocationTagData {
    name: string;
    radius: number;
    aSquare: number;
    bSquare: number;
    centerPoint: Location;
}

export type LocationTag = Entity<LocationTagData>;

export interface Entity<T>
    extends Omit<EncryptedEntity, "encryptedData" | "header"> {
    data: T;
}

export interface EntitySyncDiffResponse {
    diff: EncryptedEntity[];
}
