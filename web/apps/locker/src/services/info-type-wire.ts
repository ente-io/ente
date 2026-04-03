import type { LockerItemType } from "types";

type LockerInfoWireType =
    | "note"
    | "physical-record"
    | "account-credential"
    | "emergency-contact";

type LockerInfoInternalType = Exclude<LockerItemType, "file">;

const wireTypeByInternalType: Record<
    LockerInfoInternalType,
    LockerInfoWireType
> = {
    note: "note",
    physicalRecord: "physical-record",
    accountCredential: "account-credential",
    emergencyContact: "emergency-contact",
};

const internalTypeByWireType = new Map<string, LockerInfoInternalType>([
    ["note", "note"],
    ["physical-record", "physicalRecord"],
    ["physicalRecord", "physicalRecord"],
    ["account-credential", "accountCredential"],
    ["accountCredential", "accountCredential"],
    ["emergency-contact", "emergencyContact"],
    ["emergencyContact", "emergencyContact"],
]);

export const toInfoTypeWireValue = (
    type: LockerInfoInternalType,
): LockerInfoWireType => wireTypeByInternalType[type];

export const fromInfoTypeWireValue = (
    value: string,
): LockerItemType | undefined => internalTypeByWireType.get(value);
