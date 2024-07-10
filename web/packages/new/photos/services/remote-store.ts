import { authenticatedRequestHeaders, ensureOk } from "@/next/http";
import { apiURL } from "@/next/origins";
import { z } from "zod";

/**
 * Fetch the value of a remote value for the given {@link key}.
 */
export const getRemoteValue = async (key: string) => {
    const url = await apiURL("/remote-store");
    const params = new URLSearchParams({ key });
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const data = GetRemoteStoreResponse.parse(await res.json());
    return data?.value;
};

const GetRemoteStoreResponse = z.object({ value: z.string() }).nullable();
