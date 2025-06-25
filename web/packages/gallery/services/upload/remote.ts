import {
    authenticatedPublicAlbumsRequestHeaders,
    authenticatedRequestHeaders,
    ensureOk,
    publicRequestHeaders,
    type HTTPRequestRetrier,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL, uploaderOrigin } from "ente-base/origins";
import { RemoteEnteFile, type RemoteFileMetadata } from "ente-media/file";
import type { RemoteMagicMetadata } from "ente-media/magic-metadata";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * A pre-signed URL alongwith the associated object key that is later used to
 * refer to file contents (the "object") that were uploaded to this URL.
 */
const ObjectUploadURL = z.object({
    /**
     * The objectKey with which remote (both museum and the S3 bucket) will
     * refer to this object once it has been uploaded.
     */
    objectKey: z.string(),
    /**
     * A pre-signed URL that can be used to upload data to an S3-compatible
     * remote.
     */
    url: z.string(),
});

export type ObjectUploadURL = z.infer<typeof ObjectUploadURL>;

const ObjectUploadURLResponse = z.object({ urls: ObjectUploadURL.array() });

/**
 * Fetch a fresh list of URLs from remote that can be used to upload objects.
 *
 * @param countHint An approximate number of objects that we're expecting to
 * upload.
 *
 * @returns A list of pre-signed object URLs that can be used to upload data to
 * the S3 bucket. Each URL also has an associated "object key" with which remote
 * will refer to the uploaded object after it has been uploaded.
 */
export const fetchUploadURLs = async (countHint: number) => {
    const count = Math.min(50, countHint * 2).toString();
    const res = await fetch(await apiURL("/files/upload-urls", { count }), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return ObjectUploadURLResponse.parse(await res.json()).urls;
};

/**
 * Sibling of {@link fetchUploadURLs} for public albums.
 */
export const fetchPublicAlbumsUploadURLs = async (
    countHint: number,
    credentials: PublicAlbumsCredentials,
) => {
    const count = Math.min(50, countHint * 2).toString();
    const res = await fetch(
        await apiURL("/public-collection/upload-urls", { count }),
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
    );
    ensureOk(res);
    return ObjectUploadURLResponse.parse(await res.json()).urls;
};

/**
 * A list of URLs to use for multipart uploads.
 *
 * This is a list of pre-signed URLs (one for each part), a URL to indicate
 * completion, and an associated object key that is later used to refer to the
 * combined object from the parts there were uploaded to the part URLs.
 */
const MultipartUploadURLs = z.object({
    /**
     * The objectKey with which remote (museum and the S3 bucket) will refer to
     * this object once it has been uploaded.
     */
    objectKey: z.string(),
    /**
     * A list of pre-signed URLs that can be used to upload the parts of the
     * entire file's data to an S3-compatible remote.
     */
    partURLs: z.string().array(),
    /**
     * A pre-signed URL that can be used to finalize the multipart upload into a
     * single object on remote by providing the list of parts that were uploaded
     * (and their sequence) to the S3-compatible remote.
     */
    completeURL: z.string(),
});

export type MultipartUploadURLs = z.infer<typeof MultipartUploadURLs>;

const MultipartUploadURLsResponse = z.object({ urls: MultipartUploadURLs });

/**
 * Fetch a {@link MultipartUploadURLs} structure from remote that can be used to
 * upload a large object by splitting it into {@link uploadPartCount} parts.
 *
 * See: [Note: Multipart uploads].
 *
 * @param uploadPartCount The number of parts in which we want to upload the
 * object.
 *
 * @returns A structure ({@link MultipartUploadURLs}) containing pre-signed URLs
 * for uploading each part, a completion URL, and the final object key.
 */
export const fetchMultipartUploadURLs = async (uploadPartCount: number) => {
    const count = uploadPartCount.toString();
    const res = await fetch(
        await apiURL("/files/multipart-upload-urls", { count }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    return MultipartUploadURLsResponse.parse(await res.json()).urls;
};

/**
 * Sibling of {@link fetchMultipartUploadURLs} for public albums.
 */
export const fetchPublicAlbumsMultipartUploadURLs = async (
    uploadPartCount: number,
    credentials: PublicAlbumsCredentials,
) => {
    const count = uploadPartCount.toString();
    const res = await fetch(
        await apiURL("/public-collection/multipart-upload-urls", { count }),
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
    );
    ensureOk(res);
    return MultipartUploadURLsResponse.parse(await res.json()).urls;
};

/**
 * Upload a file using a pre-signed URL.
 *
 * @param fileUploadURL A pre-signed URL that can be used to upload data to the
 * remote S3-compatible storage.
 *
 * @param fileData The data to upload.
 *
 * @param retrier A function to wrap the request in retries if needed.
 */
export const putFile = async (
    fileUploadURL: string,
    fileData: Uint8Array,
    retrier: HTTPRequestRetrier,
) =>
    retrier(() =>
        fetch(fileUploadURL, {
            method: "PUT",
            headers: publicRequestHeaders(),
            body: fileData,
        }),
    );

/**
 * Variant of {@link putFile} that uses a CF worker.
 */
export const putFileViaWorker = async (
    fileUploadURL: string,
    fileData: Uint8Array,
    retrier: HTTPRequestRetrier,
) =>
    retrier(async () =>
        fetch(`${await uploaderOrigin()}/file-upload`, {
            method: "PUT",
            headers: { ...publicRequestHeaders(), "UPLOAD-URL": fileUploadURL },
            body: fileData,
        }),
    );

/**
 * Upload a part of a multipart upload using a pre-signed URL.
 *
 * See: [Note: Multipart uploads].
 *
 * @param partUploadURL A pre-signed URL that can be used to upload data to the
 * remote S3-compatible storage.
 *
 * @param partData The part bytes to upload.
 *
 * @param retrier A function to wrap the request in retries if needed.
 *
 * @returns the value of the "ETag" header in the remote response, or
 * `undefined` if the ETag was not present in the response (this is not expected
 * from remote in case of a successful response, but it can happen in case the
 * user has some misconfigured browser extension which is blocking the ETag
 * header from being parsed).
 */
export const putFilePart = async (
    partUploadURL: string,
    partData: Uint8Array,
    retrier: HTTPRequestRetrier,
) => {
    const res = await retrier(() =>
        fetch(partUploadURL, {
            method: "PUT",
            headers: publicRequestHeaders(),
            body: partData,
        }),
    );
    return nullToUndefined(res.headers.get("etag"));
};

/**
 * Variant of {@link putFilePart} that uses a CF worker.
 */
export const putFilePartViaWorker = async (
    partUploadURL: string,
    partData: Uint8Array,
    retrier: HTTPRequestRetrier,
) => {
    const origin = await uploaderOrigin();
    const res = await retrier(() =>
        fetch(`${origin}/multipart-upload`, {
            method: "PUT",
            headers: { ...publicRequestHeaders(), "UPLOAD-URL": partUploadURL },
            body: partData,
        }),
    );
    return z.object({ etag: z.string() }).parse(await res.json()).etag;
};

/**
 * Information about an individual part of a multipart upload that has been
 * uploaded to the remote (S3 or proxy).
 *
 * See: [Note: Multipart uploads].
 */
export interface MultipartCompletedPart {
    /**
     * The part number (1-indexed).
     *
     * The part number indicates the sequential ordering where this part belongs
     * in the overall file's data.
     */
    partNumber: number;
    /**
     * The part "ETag".
     *
     * This is the Entity tag (retrieved as the "ETag" response header) returned
     * by remote when the part was uploaded.
     */
    eTag: string;
}

/**
 * Construct an XML string of the format expected as the request body for
 * {@link _completeMultipartUpload} or
 * {@link _completeMultipartUploadViaWorker}.
 *
 * @param parts Information about the parts that were uploaded.
 */
const createMultipartUploadRequestBody = (
    parts: MultipartCompletedPart[],
): string => {
    // To avoid introducing a dependency on a XML library, we construct the
    // requisite XML by hand.
    //
    // Example:
    //
    //     <CompleteMultipartUpload>
    //         <Part>
    //             <PartNumber>1</PartNumber>
    //             <ETag>"1b3e6cdb1270c0b664076f109a7137c1"</ETag>
    //         </Part>
    //         <Part>
    //             <PartNumber>2</PartNumber>
    //             <ETag>"6049d6384a9e65694c833a3aca6584fd"</ETag>
    //         </Part>
    //         <Part>
    //             <PartNumber>3</PartNumber>
    //             <ETag>"331747eae8068f03b844e6f28cc0ed23"</ETag>
    //         </Part>
    //     </CompleteMultipartUpload>
    //
    //
    // Spec:
    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    //
    //     <CompleteMultipartUpload>
    //        <Part>
    //           <PartNumber>integer</PartNumber>
    //           <ETag>string</ETag>
    //        </Part>
    //        ...
    //     </CompleteMultipartUpload>
    //
    // Note that in the example given on the spec page, the etag strings are quoted:
    //
    //     <CompleteMultipartUpload>
    //        <Part>
    //           <PartNumber>1</PartNumber>
    //           <ETag>"a54357aff0632cce46d942af68356b38"</ETag>
    //        </Part>
    //        ...
    //     </CompleteMultipartUpload>
    //
    // No extra quotes need to be added, the etag values we get from remote
    // already quoted, we just need to pass them verbatim.

    const resultParts = parts.map(
        (part) =>
            `<Part><PartNumber>${part.partNumber}</PartNumber><ETag>${part.eTag}</ETag></Part>`,
    );
    return `<CompleteMultipartUpload>\n${resultParts.join("\n")}\n</CompleteMultipartUpload>`;
};

/**
 * Complete a multipart upload by reporting information about all the uploaded
 * parts to the provided {@link completionURL}.
 *
 * @param completionURL A pre-signed URL to which the final status of the
 * uploaded parts should be reported to.
 *
 * @param completedParts Information about all the parts of the file that have
 * been uploaded. The part numbers must start at 1 and must be consecutive.
 *
 * @param retrier A function to wrap the request in retries if needed.
 *
 * [Note: Multipart uploads]
 *
 * Multipart uploads are a mechanism to upload large files onto an remote
 * storage bucket by breaking it into smaller chunks / "parts", uploading each
 * part separately, and then reporting the consolidated information of all the
 * uploaded parts to a URL that marks the upload as complete on remote.
 *
 * This allows greater resilience since uploads of individual parts can be
 * retried independently without failing the entire upload on transient network
 * issues. This also helps self hosters, since often cloud providers have limits
 * to the size of single requests that they'll allow through (e.g. the
 * Cloudflare free plan currently has a 100 MB request size limit).
 *
 * The flow is implemented in two ways:
 *
 * a. The normal way, where each requests is made to a remote S3 bucket directly
 *    using the pre-signed URL.
 *
 * b. Using workers, where the requests are proxied via a worker near to the
 *    user's network to speed the requests up.
 *
 * See [Note: Faster uploads via workers] for more details on the worker flow.
 *
 * In both cases, the overall flow is roughly like the following:
 *
 * 1. Obtain multiple pre-signed URLs from remote (museum). The specific API
 *    call will be different (because of the different authentication
 *    mechanisms) when we're running in the context of the photos app
 *    ({@link fetchMultipartUploadURLs}) and when we're running in the context
 *    of the public albums app ({@link fetchPublicAlbumsMultipartUploadURLs}).
 *
 * 2. Break the file to be uploaded into parts, and upload each part using a PUT
 *    request to one of the pre-signed URLs we got in step 1. There are two
 *    variants of this - one where we directly upload to the remote (S3)
 *    ({@link putFilePart}), and one where we go via a worker
 *    ({@link putFilePartViaWorker}).
 *
 * 3. Once all the parts have been uploaded, send a consolidated report of all
 *    the uploaded parts (the step 2's) to remote via another pre-signed
 *    "completion URL" that we also got in step 1. Like step 2, there are 2
 *    variants of this - one where we directly tell the remote (S3)
 *    ({@link completeMultipartUpload}), and one where we report via a worker
 *    ({@link completeMultipartUploadViaWorker}).
 */
export const completeMultipartUpload = (
    completionURL: string,
    completedParts: MultipartCompletedPart[],
    retrier: HTTPRequestRetrier,
) =>
    retrier(() =>
        fetch(completionURL, {
            method: "POST",
            headers: { ...publicRequestHeaders(), "Content-Type": "text/xml" },
            body: createMultipartUploadRequestBody(completedParts),
        }),
    );

/**
 * Variant of {@link completeMultipartUpload} that uses a CF worker.
 */
export const completeMultipartUploadViaWorker = async (
    completionURL: string,
    completedParts: MultipartCompletedPart[],
    retrier: HTTPRequestRetrier,
) =>
    retrier(async () =>
        fetch(`${await uploaderOrigin()}/multipart-complete`, {
            method: "POST",
            headers: {
                ...publicRequestHeaders(),
                "Content-Type": "text/xml",
                "UPLOAD-URL": completionURL,
            },
            body: createMultipartUploadRequestBody(completedParts),
        }),
    );

export interface PostEnteFileRequest {
    collectionID: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    file: UploadedFileObjectAttributes;
    thumbnail: UploadedFileObjectAttributes;
    metadata: RemoteFileMetadata;
    pubMagicMetadata?: RemoteMagicMetadata;
}

/**
 * Attributes about an object uploaded to S3.
 *
 * This is similar to the {@link FileObjectAttributes} that we get back in the
 * {@link EnteFile} we get from remote, however it contains more fields.
 *
 * - When we're finalizing the upload of {@link EnteFile}, we have at our
 *   disposal the {@link objectKey}, {@link decryptionHeader} and {@link size}
 *   attributes that we need to set in the POST "/files" request.
 *
 * - Later when we get back the file from remote as an {@link EnteFile}, it will
 *   only have the {@link decryptionHeader}. This is all we need for obtaining
 *   the decrypted file: the contents of the file get fetched (on demand) using
 *   a presigned URL, and the file's key is the decryption key, so armed with
 *   this decryption header we are good to go.
 */
export interface UploadedFileObjectAttributes {
    /**
     * The "key" (unique ID) of the S3 object that was uploaded.
     *
     * This is not related to encryption, it is the "objectKey" that uniquely
     * identifies the S3 object that was uploaded. We get these as part of the
     * {@link ObjectUploadURL} we get from remote. We upload the contents of the
     * object (e.g. file, thumbnail) to the corresponding URL, and then report
     * back the "objectKey" in the upload finalization request.
     */
    objectKey: string;
    /**
     * The decryption header that was used when encrypting the objects's
     * contents (with the file's key) before uploading them to S3 remote.
     *
     * The {@link decryptionHeader} is both required when finalizing the upload,
     * and is also returned as part of the {@link EnteFile} that clients get
     * back from remote since it is needed (along with the file's key) to
     * decrypt the object that the client would download from S3 remote.
     */
    decryptionHeader: string;
    /**
     * The size of the uploaded object, in bytes.
     *
     * For both file and thumbnails, the client also sends the size of the
     * encrypted file (as per the client) while creating a new object on remote.
     * This allows the server to validate that the size of the objects is same
     * as what client is reporting.
     *
     * This should be present during upload, but is not returned back from
     * remote in the /diff response.
     */
    size: number;
}

/**
 * Create a new {@link EnteFile} on remote by providing remote with information
 * about the file's contents (objects) that were uploaded, and other metadata
 * about the file.
 *
 * Remote only, does not modify local state.
 *
 * @returns the newly created {@link EnteFile}.
 */
export const postEnteFile = async (
    postFileRequest: PostEnteFileRequest,
): Promise<RemoteEnteFile> => {
    const res = await fetch(await apiURL("/files"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify(postFileRequest),
    });
    ensureOk(res);
    return RemoteEnteFile.parse(await res.json());
};

/**
 * Sibling of {@link postEnteFile} for public albums.
 */
export const postPublicAlbumsEnteFile = async (
    postFileRequest: PostEnteFileRequest,

    credentials: PublicAlbumsCredentials,
): Promise<RemoteEnteFile> => {
    const res = await fetch(await apiURL("/public-collection/file"), {
        method: "POST",
        headers: authenticatedPublicAlbumsRequestHeaders(credentials),
        body: JSON.stringify(postFileRequest),
    });
    ensureOk(res);
    return RemoteEnteFile.parse(await res.json());
};
