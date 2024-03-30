import { logError } from "@ente/shared/sentry";
import { convertBytesToHumanReadable } from "@ente/shared/utils/size";

export async function getUint8ArrayView(file: Blob): Promise<Uint8Array> {
    try {
        return new Uint8Array(await file.arrayBuffer());
    } catch (e) {
        logError(e, "reading file blob failed", {
            fileSize: convertBytesToHumanReadable(file.size),
        });
        throw e;
    }
}
