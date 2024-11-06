import type { FamilyData } from "@/new/photos/services/user";
import { Subscription } from "services/plan";

export interface Bonus {
    storage: number;
    type: string;
    validTill: number;
    isRevoked: boolean;
}

export interface BonusData {
    storageBonuses: Bonus[];
}

export interface UserDetails {
    email: string;
    usage: number;
    fileCount: number;
    sharedCollectionCount: number;
    subscription: Subscription;
    familyData?: FamilyData;
    storageBonus?: number;
    bonusData?: BonusData;
}
