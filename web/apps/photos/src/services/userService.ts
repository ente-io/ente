import log from "@/next/log";
import { apiURL, customAPIOrigin, familyAppOrigin } from "@/next/origins";
import { putAttributes } from "@ente/accounts/api/user";
import { ApiError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import {
    getToken,
    setLocalMapEnabled,
} from "@ente/shared/storage/localStorage/helpers";
import { HttpStatusCode, type AxiosResponse } from "axios";
import {
    DeleteChallengeResponse,
    GetFeatureFlagResponse,
    GetRemoteStoreValueResponse,
    UserDetails,
} from "types/user";
import { getLocalFamilyData, isPartOfFamily } from "utils/user/family";

const HAS_SET_KEYS = "hasSetKeys";

export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        await apiURL("/users/public-key"),
        { email },
        {
            "X-Auth-Token": token,
        },
    );
    return resp.data.publicKey;
};

export const getPaymentToken = async () => {
    const token = getToken();

    const resp = await HTTPService.get(
        await apiURL("/users/payment-token"),
        null,
        {
            "X-Auth-Token": token,
        },
    );
    return resp.data["paymentToken"];
};

export const getFamiliesToken = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            await apiURL("/users/families-token"),
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data["familiesToken"];
    } catch (e) {
        log.error("failed to get family token", e);
        throw e;
    }
};

export const getRoadmapRedirectURL = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            await apiURL("/users/roadmap/v2"),
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data["url"];
    } catch (e) {
        log.error("failed to get roadmap url", e);
        throw e;
    }
};

export const isTokenValid = async (token: string) => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/users/session-validity/v2"),
            null,
            {
                "X-Auth-Token": token,
            },
        );
        try {
            if (resp.data[HAS_SET_KEYS] === undefined) {
                throw Error("resp.data.hasSetKey undefined");
            }
            if (!resp.data["hasSetKeys"]) {
                try {
                    await putAttributes(
                        token,
                        getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES),
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

export const getTwoFactorStatus = async () => {
    const resp = await HTTPService.get(
        await apiURL("/users/two-factor/status"),
        null,
        {
            "X-Auth-Token": getToken(),
        },
    );
    return resp.data["status"];
};

export const getUserDetailsV2 = async (): Promise<UserDetails> => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            await apiURL("/users/details/v2"),
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data;
    } catch (e) {
        log.error("failed to get user details v2", e);
        throw e;
    }
};

export const getFamilyPortalRedirectURL = async () => {
    try {
        const jwtToken = await getFamiliesToken();
        const isFamilyCreated = isPartOfFamily(getLocalFamilyData());
        return `${familyAppOrigin()}?token=${jwtToken}&isFamilyCreated=${isFamilyCreated}&redirectURL=${
            window.location.origin
        }/gallery`;
    } catch (e) {
        log.error("unable to generate to family portal URL", e);
        throw e;
    }
};

export const getAccountDeleteChallenge = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            await apiURL("/users/delete-challenge"),
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data as DeleteChallengeResponse;
    } catch (e) {
        log.error("failed to get account delete challenge", e);
        throw e;
    }
};

export const deleteAccount = async (
    challenge: string,
    reason: string,
    feedback: string,
) => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }

        await HTTPService.delete(
            await apiURL("/users/delete"),
            { challenge, reason, feedback },
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("deleteAccount api call failed", e);
        throw e;
    }
};

export const getFaceSearchEnabledStatus = async () => {
    try {
        const token = getToken();
        const resp: AxiosResponse<GetRemoteStoreValueResponse> =
            await HTTPService.get(
                await apiURL("/remote-store"),
                {
                    key: "faceSearchEnabled",
                    defaultValue: false,
                },
                {
                    "X-Auth-Token": token,
                },
            );
        return resp.data.value === "true";
    } catch (e) {
        log.error("failed to get face search enabled status", e);
        throw e;
    }
};

export const updateFaceSearchEnabledStatus = async (newStatus: boolean) => {
    try {
        const token = getToken();
        await HTTPService.post(
            await apiURL("/remote-store/update"),
            {
                key: "faceSearchEnabled",
                value: newStatus.toString(),
            },
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("failed to update face search enabled status", e);
        throw e;
    }
};

export const syncMapEnabled = async () => {
    try {
        const status = await getMapEnabledStatus();
        setLocalMapEnabled(status);
    } catch (e) {
        log.error("failed to sync map enabled status", e);
        throw e;
    }
};

export const getMapEnabledStatus = async () => {
    try {
        const token = getToken();
        const resp: AxiosResponse<GetRemoteStoreValueResponse> =
            await HTTPService.get(
                await apiURL("/remote-store"),
                {
                    key: "mapEnabled",
                    defaultValue: false,
                },
                {
                    "X-Auth-Token": token,
                },
            );
        return resp.data.value === "true";
    } catch (e) {
        log.error("failed to get map enabled status", e);
        throw e;
    }
};

export const updateMapEnabledStatus = async (newStatus: boolean) => {
    try {
        const token = getToken();
        await HTTPService.post(
            await apiURL("/remote-store/update"),
            {
                key: "mapEnabled",
                value: newStatus.toString(),
            },
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("failed to update map enabled status", e);
        throw e;
    }
};

/**
 * Return true to disable the upload of files via Cloudflare Workers.
 *
 * These workers were introduced as a way of make file uploads faster:
 * https://ente.io/blog/tech/making-uploads-faster/
 *
 * By default, that's the route we take. However, during development or when
 * self-hosting it can be convenient to turn this flag on to directly upload to
 * the S3-compatible URLs returned by the ente API.
 *
 * Note the double negative (Enhancement: maybe remove the double negative,
 * rename this to say getUseDirectUpload).
 */
export async function getDisableCFUploadProxyFlag(): Promise<boolean> {
    // If a custom origin is set, that means we're not running a production
    // deployment (maybe we're running locally, or being self-hosted).
    //
    // In such cases, disable the Cloudflare upload proxy (which won't work for
    // self-hosters), and instead just directly use the upload URLs that museum
    // gives us.
    if (await customAPIOrigin()) return true;

    try {
        const featureFlags = (
            await fetch("https://static.ente.io/feature_flags.json")
        ).json() as GetFeatureFlagResponse;
        return featureFlags.disableCFUploadProxy;
    } catch (e) {
        log.error("failed to get feature flags", e);
        return false;
    }
}
