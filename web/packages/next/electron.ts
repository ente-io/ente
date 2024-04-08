import type { ElectronAPIsType } from "./types/ipc";

// TODO (MR):
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const ElectronAPIs = (globalThis as unknown as any)[
    // eslint-disable-next-line @typescript-eslint/dot-notation, @typescript-eslint/no-unsafe-member-access
    "ElectronAPIs"
] as ElectronAPIsType;

export default ElectronAPIs;
