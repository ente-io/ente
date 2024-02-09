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

/*
It's a dev deployment (and should use the environment override for endpoints ) in three cases:
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
