import { assertionFailed } from "@/base/assert";
import { decryptBlob } from "@/base/crypto";
import log from "@/base/log";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { fetchFileData } from "./file-data";

/**
 * Return a HLS playlist that can be used to stream playback of thne given video
 * {@link file}.
 *
 * @param file An {@link EnteFile} of type video.
 *
 * [Note: Video playlist and preview]
 *
 * In museum's ontology, there is a distinction between two concepts:
 *
 * S3 metadata is the data that museum uploads (on behalf of the client):
 * - ML data.
 * - Preview video playlist.
 *
 * S3 file data is the data that client uploads:
 * - Preview video itself.
 * - Additional preview images.
 *
 * Because of this separation, there are separate code paths dealing with the
 * two parts we need to play streaming video:
 *
 * - The encrypted HLS playlist (which is stored as file data of type
 *   "vid_preview"),
 *
 * - And the encrypted video chunks that it (the playlist) refers to (which are
 *   stored as file preview data of type "vid_preview").
 */
export const hlsPlaylistForFile = async (file: EnteFile) => {
    if (file.metadata.fileType != FileType.video) {
        assertionFailed();
        return undefined;
    }

    const encryptedPlaylist = await fetchFileData("vid_preview", file.id);
    if (!encryptedPlaylist) return undefined;

    const playlist = new TextDecoder().decode(
        await decryptBlob(encryptedPlaylist, file.key),
    );
    log.debug(() => ["hlsPlaylistForFile", playlist]);
    return file.id;
};
