import { convertBytesToHumanReadable } from "@/next/file";
import log from "@/next/log";

export async function getUint8ArrayView(file: Blob): Promise<Uint8Array> {
    try {
        return new Uint8Array(await file.arrayBuffer());
    } catch (e) {
        log.error(
            `Failed to read file blob of size ${convertBytesToHumanReadable(file.size)}`,
            e,
        );
        throw e;
    }
}
