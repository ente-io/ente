export class AuthEntity {
    id: string;
    encryptedData: string | null;
    header: string | null;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
    constructor(
        id: string,
        encryptedData: string | null,
        header: string | null,
        isDeleted: boolean,
        createdAt: number,
        updatedAt: number
    ) {
        this.id = id;
        this.encryptedData = encryptedData;
        this.header = header;
        this.isDeleted = isDeleted;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
