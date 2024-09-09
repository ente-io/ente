export enum REDIRECTS {
    FAMILIES = "families",
}

export const getRedirectURL = (redirect: REDIRECTS) => {
    const url = new URL("https://web.ente.io");
    url.searchParams.set("redirect", redirect);
    return url.href;
};
