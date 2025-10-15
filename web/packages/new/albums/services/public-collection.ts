import { deriveKey } from "ente-base/crypto";
import {
    authenticatedPublicAlbumsRequestHeaders,
    ensureOk,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import {
    decryptRemoteCollection,
    RemoteCollection,
    type Collection,
    type PublicURL,
} from "ente-media/collection";
import {
    decryptRemoteFile,
    FileDiffResponse,
    type EnteFile,
} from "ente-media/file";
import { z } from "zod";
import {
    removePublicCollectionAccessTokenJWT,
    removePublicCollectionFiles,
    removePublicCollectionLastSyncTime,
    savedPublicCollectionFiles,
    savedPublicCollectionLastSyncTime,
    saveLastPublicCollectionReferralCode,
    savePublicCollection,
    savePublicCollectionFiles,
    savePublicCollectionLastSyncTime,
} from "./public-albums-fdb";

/**
 * Verify with remote that the password entered by the user is the same as the
 * password that was set by the person who shared the public album.
 *
 * The verification is done on a password hash that we check with remote. If
 * they match, remote will provide us with another token that can be used to
 * make API calls for this password protected public album.
 *
 * If they don't match, or if {@link accessToken} itself has expired, then
 * remote will return a HTTP 401.
 *
 * @param publicURL Data about the public album.
 *
 * @param password The password entered by the user.
 *
 * @param token The access token to make API requests for a particular public
 * album.
 *
 * @returns A accessTokenJWT.
 *
 * See [Note: Password token for public albums requests]
 */
export const verifyPublicAlbumPassword = async (
    publicURL: PublicURL,
    password: string,
    accessToken: string,
) => {
    const passwordHash = await deriveKey(
        password,
        // TODO: Fix the types to not require the bang.
        publicURL.nonce!,
        publicURL.opsLimit!,
        publicURL.memLimit!,
    );

    const res = await fetch(
        await apiURL("/public-collection/verify-password"),
        {
            method: "POST",
            headers: authenticatedPublicAlbumsRequestHeaders({ accessToken }),
            body: JSON.stringify({ passHash: passwordHash }),
        },
    );
    ensureOk(res);
    return z.object({ jwtToken: z.string() }).parse(await res.json()).jwtToken;
};

/**
 * Fetch a public collection from remote using its access key, decrypt it using
 * the provided key, save the collection in our local database for subsequent
 * use, and return it.
 *
 * This function modifies local state.
 *
 * @param accessToken A public collection access key obtained from the "t="
 * query parameter of the public URL.
 *
 * The access key serves to both identify the public collection, and also
 * authenticate the request. See: [Note: Public album access token].
 *
 * @param collectionKey The base64 encoded key that can be used to decrypt the
 * collection obtained from remote.
 *
 * The collection key is obtained from the fragment portion of the public URL
 * (the fragment is a client side only portion that can be used to have local
 * secrets that are not sent by the browser to the server).
 */
export const pullCollection = async (
    accessToken: string,
    collectionKey: string,
): Promise<{ collection: Collection; referralCode: string }> => {
    const { collection: remoteCollection, referralCode } =
        await getPublicCollectionInfo(accessToken);

    const collection = await decryptRemoteCollection(
        remoteCollection,
        collectionKey,
    );

    await savePublicCollection(collection);
    await saveLastPublicCollectionReferralCode(referralCode);

    return { collection, referralCode };
};

const PublicCollectionInfo = z.object({
    collection: RemoteCollection,
    /**
     * A referral code of the owner of the public album.
     *
     * [Note: Public albums referral code]
     *
     * The information of a public collection contains the referral code of the
     * person who shared the album. This allows both the viewer and the sharer
     * to gain storage bonus.
     */
    referralCode: z.string(),
});

/**
 * Fetch information from remote about a public collection using its access key.
 *
 * Remote only, does not modify local state.
 *
 * @param accessToken A public collection access key.
 */
const getPublicCollectionInfo = async (accessToken: string) => {
    const res = await fetch(await apiURL("/public-collection/info"), {
        headers: authenticatedPublicAlbumsRequestHeaders({ accessToken }),
    });
    ensureOk(res);
    return PublicCollectionInfo.parse(await res.json());
};

/**
 * Pull any changes to the files belonging to the given collection, updating our
 * local database and also calling the provided callback.
 *
 * This function modifies local state.
 *
 * The pull uses a persisted timestamp for the most recent change we've already
 * fetched, and will be only fetch the delta of changes since the last pull. The
 * files are fetched in a paginated manner, so the provided callback can get
 * called multiple times during the pull (one for each page).
 *
 * @param credentials A public collection access key and an optional password
 * unlocked access token JWT. The credentials serve to both identify the
 * collection, and authenticate the request.
 *
 * @param collection The public collection corresponding to the credentials.
 *
 * This function assumes that collection has already been pulled from remote and
 * is at its latest, remote, value. This assumption is used to skip fetching
 * files if the collection has not changed on remote (any updates to the files
 * will also increase the updation time of the collection that contains them).
 *
 * @param onSetFiles A callback that is invoked each time a new batch of updates
 * to the collection's files is fetched and processed. The callback is called
 * the consolidated list of files after applying the updates received so far.
 *
 * The provided files are in an arbitrary order, and must be sorted before use.
 *
 * This callback can get called multiple times during the pull. The callback can
 * also never get called if no changes were pulled (or needed to be pulled).
 */
export const pullPublicCollectionFiles = async (
    credentials: PublicAlbumsCredentials,
    collection: Collection,
    onSetFiles: (files: EnteFile[]) => void,
) => {
    const { accessToken } = credentials;

    let sinceTime = (await savedPublicCollectionLastSyncTime(accessToken)) ?? 0;

    // Prior to reaching here, we would've already fetched the latest
    // collection. If the updation time of the collection is the same as the
    // last sync time, then we know there were no new updates (since updates to
    // files also increase the updation time of their containing collection).
    if (sinceTime == collection.updationTime) return;

    const files = await savedPublicCollectionFiles(accessToken);
    const filesByID = new Map(files.map((f) => [f.id, f]));

    while (true) {
        const { diff, hasMore } = await getPublicCollectionDiff(
            credentials,
            sinceTime,
        );
        if (!diff.length) break;
        for (const change of diff) {
            sinceTime = Math.max(sinceTime, change.updationTime);
            if (change.isDeleted) {
                filesByID.delete(change.id);
            } else {
                filesByID.set(
                    change.id,
                    await decryptRemoteFile(change, collection.key),
                );
            }
        }

        const files = [...filesByID.values()];
        await savePublicCollectionFiles(accessToken, files);
        await savePublicCollectionLastSyncTime(accessToken, sinceTime);
        onSetFiles(files);

        if (!hasMore) break;
    }
};

/**
 * Fetch the public collection diff to obtain updates to the collection
 * (identified by its {@link credentials}) since {@link sinceTime}.
 *
 * Remote only, does not modify local state.
 */
const getPublicCollectionDiff = async (
    credentials: PublicAlbumsCredentials,
    sinceTime: number,
) => {
    const res = await fetch(
        await apiURL("/public-collection/diff", { sinceTime }),
        { headers: authenticatedPublicAlbumsRequestHeaders(credentials) },
    );
    ensureOk(res);
    return FileDiffResponse.parse(await res.json());
};

/**
 * Remove the files, sync time and accessTokenJWT associated with the given
 * collection (identified by its {@link accessToken}).
 *
 * This function modifies local state.
 */
export const removePublicCollectionFileData = async (accessToken: string) => {
    await Promise.all([
        removePublicCollectionAccessTokenJWT(accessToken),
        removePublicCollectionLastSyncTime(accessToken),
        removePublicCollectionFiles(accessToken),
    ]);
};
