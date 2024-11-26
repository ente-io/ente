import { authenticatedRequestHeaders } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { ApiError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";

/**
 * Revoke all existing outstanding cast tokens for the current user on remote.
 */
export const revokeAllCastTokens = async () =>
    fetch(await apiURL("/cast/revoke-all-tokens"), {
        method: "DELETE",
        headers: await authenticatedRequestHeaders(),
    });

class CastGateway {
    public async getPublicKey(code: string): Promise<string> {
        let resp;
        try {
            const token = getToken();
            resp = await HTTPService.get(
                await apiURL(`/cast/device-info/${code}`),
                undefined,
                {
                    "X-Auth-Token": token,
                },
            );
        } catch (e) {
            if (e instanceof ApiError && e.httpStatusCode === 404) {
                return "";
            }
            log.error("failed to getPublicKey", e);
            throw e;
        }
        return resp.data.publicKey;
    }

    public async publishCastPayload(
        code: string,
        castPayload: string,
        collectionID: number,
        castToken: string,
    ) {
        const token = getToken();
        await HTTPService.post(
            await apiURL("/cast/cast-data"),
            {
                // eslint-disable-next-line @typescript-eslint/no-unnecessary-template-expression
                deviceCode: `${code}`,
                encPayload: castPayload,
                collectionID: collectionID,
                castToken: castToken,
            },
            undefined,
            { "X-Auth-Token": token },
        );
    }
}

export default new CastGateway();
