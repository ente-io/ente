import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { z } from "zod";

/**
 * Revoke all existing outstanding cast tokens for the current user on remote.
 */
export const revokeAllCastTokens = async () =>
    fetch(await apiURL("/cast/revoke-all-tokens"), {
        method: "DELETE",
        headers: await authenticatedRequestHeaders(),
    });

/**
 * Fetch the public key (represented as a base64 string) associated with the
 * given device / pairing {@link code} from remote, or `undefined` if there is
 * no public key associated with the given code.
 */
export const publicKeyForPairingCode = async (code: string) => {
    const res = await fetch(await apiURL(`/cast/device-info/${code}`), {
        headers: await authenticatedRequestHeaders(),
    });
    if (res.status == 404) return undefined;
    ensureOk(res);
    return z.object({ publicKey: z.string() }).parse(await res.json())
        .publicKey;
};

class CastGateway {
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
