import { decryptBlob } from "@/base/crypto";
import type { EncryptedBlob } from "@/base/crypto/types";
import log from "@/base/log";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { gunzip } from "@/new/photos/utils/gzip";
import { ensurePrecondition } from "@/utils/ensure";
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
    ensurePrecondition(file.metadata.fileType == FileType.video);

    const playlistFileData = await fetchFileData("vid_preview", file.id);
    if (!playlistFileData) return undefined;

    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const { playlist } = await decryptPlaylistJSON(playlistFileData, file);

    // [Note: HLS playlist format]
    //
    // The decrypted playlist is a regular HLS playlist for an encrypted media
    // stream, except that it uses a placeholder "output.ts" which needs to be
    // replaced with the URL of the actual encrypted video data. A single URL
    // pointing to the entire encrypted video data suffices; the individual
    // chunks are fetched by HTTP range requests.
    //
    // Here is an example of what the contents of the `playlist` variable might
    // look like at this point:
    //
    //     #EXTM3U
    //     #EXT-X-VERSION:4
    //     #EXT-X-TARGETDURATION:8
    //     #EXT-X-MEDIA-SEQUENCE:0
    //     #EXT-X-KEY:METHOD=AES-128,URI="data:text/plain;base64,XjvG7qeRrsOpPUbJPh2Ikg==",IV=0x00000000000000000000000000000000
    //     #EXTINF:8.333333,
    //     #EXT-X-BYTERANGE:3046928@0
    //     output.ts
    //     #EXTINF:8.333333,
    //     #EXT-X-BYTERANGE:3012704@3046928
    //     output.ts
    //     #EXTINF:2.200000,
    //     #EXT-X-BYTERANGE:834736@6059632
    //     output.ts
    //     #EXT-X-ENDLIST
    //
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
