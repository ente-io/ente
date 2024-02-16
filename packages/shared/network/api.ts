export const getEndpoint = () => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return endpoint;
    }
    return 'https://api.ente.io';
};

export const getFileURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return `${endpoint}/files/download/${id}`;
    }
    return `https://files.ente.io/?fileID=${id}`;
};

export const getPublicCollectionFileURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return `${endpoint}/public-collection/files/download/${id}`;
    }
    return `https://public-albums.ente.io/download/?fileID=${id}`;
};

export const getCastFileURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return `${endpoint}/cast/files/download/${id}`;
    }
    return `https://cast-albums.ente.io/download/?fileID=${id}`;
};

export const getCastThumbnailURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (isDevDeployment() && endpoint) {
        return `${endpoint}/cast/files/preview/${id}`;
    }
    return `https://cast-albums.ente.io/preview/?fileID=${id}`;
};

export const getThumbnailURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return `${endpoint}/files/preview/${id}`;
    }
    return `https://thumbnails.ente.io/?fileID=${id}`;
};

export const getPublicCollectionThumbnailURL = (id: number) => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return `${endpoint}/public-collection/files/preview/${id}`;
    }
    return `https://public-albums.ente.io/preview/?fileID=${id}`;
};

export const getUploadEndpoint = () => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return endpoint;
    }
    return `https://uploader.ente.io`;
};

export const getPaymentsURL = () => {
    const paymentsURL = process.env.NEXT_PUBLIC_ENTE_PAYMENT_ENDPOINT;
    if (paymentsURL) {
        return paymentsURL;
    }
    return `https://payments.ente.io`;
};

export const getAlbumsURL = () => {
    const albumsURL = process.env.NEXT_PUBLIC_ENTE_ALBUM_ENDPOINT;
    if (albumsURL) {
        return albumsURL;
    }
    return `https://albums.ente.io`;
};

/**
 * Return the URL for the family dashboard which can be used to create or manage
 * family plans.
 */
export const getFamilyPortalURL = () => {
    const familyURL = process.env.NEXT_PUBLIC_ENTE_FAMILY_PORTAL_ENDPOINT;
    if (familyURL) {
        return familyURL;
    }
    return `https://family.ente.io`;
};

// getAuthenticatorURL returns the endpoint for the authenticator which can be used to
// view authenticator codes.
export const getAuthURL = () => {
    const authURL = process.env.NEXT_PUBLIC_ENTE_AUTH_ENDPOINT;
    if (isDevDeployment() && authURL) {
        return authURL;
    }
    return `https://auth.ente.io`;
};

export const getAccountsURL = () => {
    const accountsURL = process.env.NEXT_PUBLIC_ENTE_ACCOUNTS_ENDPOINT;
    if (isDevDeployment() && accountsURL) {
        return accountsURL;
    }
    return `https://accounts.ente.io`;
};

export const getSentryTunnelURL = () => {
    return `https://sentry-reporter.ente.io`;
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
/**
 * A build is considered as a development build if either the NODE_ENV is
 * environment variable is set to 'development'.
 *
 * NODE_ENV is automatically set to 'development' when we run `yarn dev`. From
 * Next.js docs:
 *
 * > If the environment variable NODE_ENV is unassigned, Next.js automatically
 *   assigns development when running the `next dev` command, or production for
 *   all other commands.
 */
export const isDevBuild = process.env.NODE_ENV === 'development';
