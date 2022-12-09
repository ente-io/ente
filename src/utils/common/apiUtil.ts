export const getEndpoint = () => {
    const endPoint =
        process.env.NEXT_PUBLIC_ENTE_ENDPOINT ?? 'https://api.ente.io';
    return endPoint;
};

export const getFileURL = (id: number) => {
    if (process.env.NEXT_PUBLIC_ENTE_ENDPOINT !== undefined) {
        return `${process.env.NEXT_PUBLIC_ENTE_ENDPOINT}/files/download/${id}`;
    }
    return `https://files.ente.io/?fileID=${id}`;
};

export const getPublicCollectionFileURL = (id: number) => {
    if (process.env.NEXT_PUBLIC_ENTE_ENDPOINT !== undefined) {
        return `${process.env.NEXT_PUBLIC_ENTE_ENDPOINT}/public-collection/files/download/${id}`;
    }
    return `https://public-albums.ente.io/download/?fileID=${id}`;
};

export const getThumbnailURL = (id: number) => {
    if (process.env.NEXT_PUBLIC_ENTE_ENDPOINT !== undefined) {
        return `${process.env.NEXT_PUBLIC_ENTE_ENDPOINT}/files/preview/${id}`;
    }
    return `https://thumbnails.ente.io/?fileID=${id}`;
};

export const getPublicCollectionThumbnailURL = (id: number) => {
    if (process.env.NEXT_PUBLIC_ENTE_ENDPOINT !== undefined) {
        return `${process.env.NEXT_PUBLIC_ENTE_ENDPOINT}/public-collection/files/preview/${id}`;
    }
    return `https://public-albums.ente.io/preview/?fileID=${id}`;
};

export const getSentryTunnelURL = () => {
    return `https://sentry-reporter.ente.io`;
};

export const getPaymentsURL = () => {
    if (process.env.NEXT_PUBLIC_ENTE_ENDPOINT !== undefined) {
        return process.env.NEXT_PUBLIC_ENTE_PAYMENT_ENDPOINT;
    }
    return `https://payments.ente.io`;
};

export const getAlbumsURL = () => {
    const albumsURL = process.env.NEXT_PUBLIC_ENTE_PAYMENT_ENDPOINT;
    if (isDevDeployment() && albumsURL) {
        return albumsURL;
    }
    return `https://albums.ente.io`;
};

// getFamilyPortalURL returns the endpoint for the family dashboard which can be used to
// create or manage family.
export const getFamilyPortalURL = () => {
    if (process.env.NEXT_PUBLIC_ENTE_FAMILY_PORTAL_ENDPOINT !== undefined) {
        return process.env.NEXT_PUBLIC_ENTE_FAMILY_PORTAL_ENDPOINT;
    }
    return `https://family.ente.io`;
};

export const getUploadEndpoint = () => {
    if (process.env.NEXT_PUBLIC_ENTE_UPLOAD_ENDPOINT !== undefined) {
        return process.env.NEXT_PUBLIC_ENTE_UPLOAD_ENDPOINT;
    }
    return `https://uploader.ente.io`;
};

export const isDevDeployment = () =>
    process.env.NEXT_PUBLIC_ENTE_DEV_APP_URL === window.location.origin;
