const apiOrigin = import.meta.env.VITE_ENTE_ENDPOINT ?? "https://api.ente.io";

/** Fetch details of the user associated with the given {@link authToken}. */
export const getUserDetails = async (authToken: string) => {
    const url = `${apiOrigin}/users/details/v2`;
    const res = await fetch(url, {
        headers: {
            "X-Auth-Token": authToken,
        },
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const json: unknown = await res.json();
    if (json && typeof json === "object") {
        return json;
    }
    throw new Error(`Unexpected response for ${url}: ${JSON.stringify(json)}`);
};
