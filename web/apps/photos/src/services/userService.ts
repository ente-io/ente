import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import type { UserDetails } from "ente-new/photos/services/user-details";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";

export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        await apiURL("/users/public-key"),
        { email },
        { "X-Auth-Token": token },
    );
    return resp.data.publicKey;
};

export const getUserDetailsV2 = async (): Promise<UserDetails> => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            await apiURL("/users/details/v2"),
            null,
            { "X-Auth-Token": token },
        );
        return resp.data;
    } catch (e) {
        log.error("failed to get user details v2", e);
        throw e;
    }
};
