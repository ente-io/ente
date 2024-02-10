export const getEndpoint = () => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return endpoint;
    }
    return 'https://api.ente.io';
};

export const getFileURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return `${endpoint}/files/download/${id}`;
    }
    return `https://files.ente.io/?fileID=${id}`;
};

export const getPublicCollectionFileURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return `${endpoint}/public-collection/files/download/${id}`;
    }
    return `https://public-albums.ente.io/download/?fileID=${id}`;
};

export const getThumbnailURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return `${endpoint}/files/preview/${id}`;
    }
    return `https://thumbnails.ente.io/?fileID=${id}`;
};

export const getPublicCollectionThumbnailURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return `${endpoint}/public-collection/files/preview/${id}`;
    }
    return `https://public-albums.ente.io/preview/?fileID=${id}`;
};

export const getUploadEndpoint = () => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_UPLOAD_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return endpoint;
    }
    return `https://uploader.ente.io`;
};

export const getPaymentsURL = () => {
    const paymentsURL = process.env.NEXT_PUBLIC_ENTE_PAYMENT_ENDPOINT;
    if (isDevDeployment() && paymentsURL) {
        return paymentsURL;
    }
    return `https://payments.ente.io`;
};

export const getAlbumsURL = () => {
    const albumsURL = process.env.NEXT_PUBLIC_ENTE_ALBUM_ENDPOINT;
    if (isDevDeployment() && albumsURL) {
        return albumsURL;
    }
    return `https://albums.ente.io`;
};

// getFamilyPortalURL returns the endpoint for the family dashboard which can be used to
// create or manage family.
export const getFamilyPortalURL = () => {
    const familyURL = process.env.NEXT_PUBLIC_ENTE_FAMILY_PORTAL_ENDPOINT;
    if (isDevDeployment() && familyURL) {
        return familyURL;
    }
    return `https://family.ente.io`;
};

/**
 * A build is considered as a development build if one of the following holds:
 *
 * 1. The NODE_ENV environment variable is set to 'development'. This
 *    automatically happens when we run `yarn dev:foo`, but we can also
 *    explictly set this to development before invoking the build. From the
 *    Next.js docs:
 *
 *    > If the environment variable NODE_ENV is unassigned, Next.js
 *    > automatically assigns development when running the `next dev` command,
 *    > or production for all other commands.
 *
 * 2. Sometimes we're building for a remote deployment, but we want the deployed
      site to behave as a development build. For example, when deploying the
      main branch to `testing.ente.io`. In these cases, since the build was done
      using `yarn export` (which in turn invokes `next build`), the NODE_ENV
      will not get set to 'development'. To handle such cases, we introduce
      another variable, NEXT_PUBLIC_ENTE_ENV, which has the same semantics as
 *
 *
 * If the environment variable NODE_ENV is unassigned, Next.js automatically
   assigns development when running the next dev command, or production for all
   other commands.
 *    next sets NODE_ENV to `production`.
 *  When we run
 *    `yarn dev:foo`, it invokes `next dev`, which sets NODE_ENV to
 *    'development'. In all other cases (say, `next build`),
 *

It's a dev deployment (and should use the environment override for endpoints )
in three cases:
1. when the URL opened is that of the staging web app, or
2. when the URL opened is that of the staging album app, or
3. if the app is running locally (hence node_env is development)
4. if the app is running in test mode
*/
export const isDevDeployment = () => {
    if (globalThis?.location) {
        return (
            process.env.NEXT_PUBLIC_ENTE_WEB_ENDPOINT ===
                globalThis.location.origin ||
            process.env.NEXT_PUBLIC_ENTE_ALBUM_ENDPOINT ===
                globalThis.location.origin ||
            process.env.NEXT_PUBLIC_IS_TEST_APP === 'true' ||
            process.env.NODE_ENV === 'development'
        );
    }
};
