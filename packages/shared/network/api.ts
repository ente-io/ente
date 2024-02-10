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
 * A build is considered as a development build if the NODE_ENV environment
 * variable is set to 'development'.
 *
 * This automatically happens when we run `yarn dev:foo`, but we can also
 * explictly set it to development before invoking the build. From Next.js docs:
 *
 * > If the environment variable NODE_ENV is unassigned, Next.js
 *   automatically assigns development when running the `next dev` command,
 *   or production for all other commands.
 */
export const isDevDeployment = () => {
    return process.env.NODE_ENV === 'development';
};
