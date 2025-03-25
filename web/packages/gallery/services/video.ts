import { decryptBlob } from "@/base/crypto";
import type { EncryptedBlob } from "@/base/crypto/types";
import log from "@/base/log";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { gunzip } from "@/new/photos/utils/gzip";
import { ensurePrecondition } from "@/utils/ensure";
import { z } from "zod";
import { fetchFileData, fetchFilePreviewData } from "./file-data";

/**
 * Return a HLS playlist that can be used to stream playback of thne given video
 * {@link file}.
 *
 * @param file An {@link EnteFile} of type video.
 *
 * @returns The HLS playlist as a string, or `undefined` if there is no video
 * preview associated with the given file.
 *
 * See: [Note: Video playlist and preview]
 */
export const hlsPlaylistForFile = async (file: EnteFile) => {
    ensurePrecondition(file.metadata.fileType == FileType.video);

    const playlistFileData = await fetchFileData("vid_preview", file.id);
    if (!playlistFileData) return undefined;

    const videoURL = await fetchFilePreviewData("vid_preview", file.id);
    if (!videoURL) return undefined;

    const { playlist: playlistTemplate } = await decryptPlaylistJSON(
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        playlistFileData,
        file,
    );

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
    // The HLS playlist format is specified in RFC 8216:
    // https://datatracker.ietf.org/doc/html/rfc8216
    //
    // Some notes pertinent to us:
    //
    // - A URI line identifies a media segment.
    //
    // - The EXTINF tag specifies the duration of the media segment (applies
    //   only to the next URI line that follows it in the playlist).
    //
    // - The EXT-X-BYTERANGE tag indicates that a media segment is a sub-range
    //   of the resource identified by its URI (applies only to the next URI
    //   line that follows it in the playlist). The value should be of the
    //   format `<n>[@<o>]` where n is an integer indicating the length of the
    //   sub-range in bytes, and if present, o is the integer indicating the
    //   start of the sub-range as a byte offset from the beginning of the
    //   resource. If o is not present, the sub-range begins at the next byte
    //   following the sub-range of the preivous media segment.
    //
    // - Media segments may be encrypted, and the EXT-X-KEY tag specifies how to
    //   decrypt them. It applies to all subsequent media segment (until another
    //   EXT-X-KEY). Value is an `<attribute-list>`, consisting of the METHOD
    //   (AES-128 for us), URI and IV attributes. The URI attribute value is a
    //   quoted string containing a URI that specfies how to obtain the key.

    const playlist = playlistTemplate.replaceAll("output.ts", videoURL);
    log.debug(() => ["hlsPlaylistForFile", playlist]);

    const playlistBlob = new File([playlist], "vid.m3u8", {
        type: "application/vnd.apple.mpegurl",
    });
    const playlistURL = await blobToDataURL(playlistBlob);

    return playlistURL;
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

/**
 * Convert a blob to a `data:` URL.
 */
const blobToDataURL = (blob: Blob) =>
    new Promise<string>((resolve) => {
        const reader = new FileReader();
        // We need to cast to a string here. This should be safe since MDN says:
        //
        // > the result attribute contains the data as a data: URL representing
        // > the file's data as a base64 encoded string.
        // >
        // > https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsDataURL
        reader.onload = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
    });
