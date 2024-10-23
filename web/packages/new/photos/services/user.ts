export interface FamilyMember {
    email: string;
    usage: number;
    id: string;
    isAdmin: boolean;
}

export interface FamilyData {
    storage: number;
    expiry: number;
    members: FamilyMember[];
}
