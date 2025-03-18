import type { EnteFile } from "@/media/file";
import { wait } from "@/utils/promise";

/**
 * Return a HLS playlist that can be used to stream playback of thne given video
 * {@link file}.
 *
 * @param file An {@link EnteFile} of type
 */
export const hlsPlaylistForFile = async (file: EnteFile) => {
    await wait(0);
    return file.id;
};
