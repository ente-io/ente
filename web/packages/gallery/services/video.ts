import { assertionFailed } from "@/base/assert";
import { decryptBlob } from "@/base/crypto";
import type { EncryptedBlob } from "@/base/crypto/types";
import log from "@/base/log";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { gunzip } from "@/new/photos/utils/gzip";
import { z } from "zod";
import { fetchFileData } from "./file-data";

/**
 * Return a HLS playlist that can be used to stream playback of thne given video
 * {@link file}.
 *
 * @param file An {@link EnteFile} of type video.
 *
 * @returns The HLS playlist as a string, or `undefined` if there is no video
 * preview associated with the given file.
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

    const playlistFileData = await fetchFileData("vid_preview", file.id);
    if (!playlistFileData) return undefined;

    const { playlist } = await decryptPlaylistJSON(playlistFileData, file);

    log.debug(() => ["hlsPlaylistForFile", playlist]);
    return file.id;
};

const PlaylistJSON = z.object({
    /** The HLS playlist, as a string. */
    playlist: z.string(),
});

const decryptPlaylistJSON = async (
    encryptedPlaylist: EncryptedBlob,
    file: EnteFile,
) => {
    const decryptedBytes = await decryptBlob(encryptedPlaylist, file.key);
    const jsonString = await gunzip(decryptedBytes);
    return PlaylistJSON.parse(JSON.parse(jsonString));
};
