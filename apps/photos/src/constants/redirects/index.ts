export enum REDIRECTS {
    ROADMAP = 'roadmap',
    FAMILIES = 'families',
}

export const getRedirectURL = (redirect: REDIRECTS) => {
    // open current app with query param of redirect = roadmap
    const url = new URL(window.location.href);
    url.searchParams.set('redirect', redirect);
    return url.href;
};
