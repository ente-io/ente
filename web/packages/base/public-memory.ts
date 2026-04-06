import { publicRequestHeaders } from "ente-base/http";

/**
 * Credentials needed to make public memory share related API requests.
 */
export interface PublicMemoryCredentials {
    /**
     * The access token for the public memory share.
     *
     * This is obtained from the "t" query parameter of the share URL.
     * It both identifies the share and authenticates the request.
     */
    accessToken: string;
}

/**
 * Return headers for public memory share API requests.
 */
export const authenticatedPublicMemoryRequestHeaders = ({
    accessToken,
}: PublicMemoryCredentials) => ({
    "X-Auth-Access-Token": accessToken,
    ...publicRequestHeaders(),
});
