import { HttpStatusCode } from "axios";
import { putAttributes } from "ente-accounts/services/user";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import type { UserDetails } from "ente-new/photos/services/user-details";
import { ApiError } from "ente-shared/error";
import HTTPService from "ente-shared/network/HTTPService";
import { getData } from "ente-shared/storage/localStorage";
import { getToken } from "ente-shared/storage/localStorage/helpers";

const HAS_SET_KEYS = "hasSetKeys";

export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        await apiURL("/users/public-key"),
        { email },
        { "X-Auth-Token": token },
    );
    return resp.data.publicKey;
};

export const isTokenValid = async (token: string) => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/users/session-validity/v2"),
            null,
            { "X-Auth-Token": token },
        );
        try {
            if (resp.data[HAS_SET_KEYS] === undefined) {
                throw Error("resp.data.hasSetKey undefined");
            }
            if (!resp.data.hasSetKeys) {
                try {
                    await putAttributes(
                        token,
                        getData("originalKeyAttributes"),
                    );
                } catch (e) {
                    log.error("put attribute failed", e);
                }
            }
        } catch (e) {
            log.error("hasSetKeys not set in session validity response", e);
        }
        return true;
    } catch (e) {
        log.error("session-validity api call failed", e);
        if (
            e instanceof ApiError &&
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            return false;
        } else {
            return true;
        }
    }
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
