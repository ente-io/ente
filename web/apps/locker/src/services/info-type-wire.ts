import type { LockerItemType } from "types";

type LockerInfoWireType =
    | "note"
    | "physical-record"
    | "account-credential"
    | "emergency-contact";

const wireTypeByInternalType: Record<
    Exclude<LockerItemType, "file">,
    LockerInfoWireType
> = {
    note: "note",
    physicalRecord: "physical-record",
    accountCredential: "account-credential",
    emergencyContact: "emergency-contact",
};

const internalTypeByWireType: Record<string, Exclude<LockerItemType, "file">> = {
    note: "note",
    "physical-record": "physicalRecord",
    physicalRecord: "physicalRecord",
    "account-credential": "accountCredential",
    accountCredential: "accountCredential",
    "emergency-contact": "emergencyContact",
    emergencyContact: "emergencyContact",
};

export const toInfoTypeWireValue = (
    type: Exclude<LockerItemType, "file">,
): LockerInfoWireType => wireTypeByInternalType[type];

export const fromInfoTypeWireValue = (
    value: string,
): LockerItemType | undefined => internalTypeByWireType[value];
