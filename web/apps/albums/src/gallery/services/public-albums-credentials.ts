import type { PublicAlbumsCredentials } from "ente-base/http";

let publicAlbumsCredentials: PublicAlbumsCredentials | undefined;

export const getPublicAlbumsCredentials = () => publicAlbumsCredentials;

export const setPublicAlbumsCredentials = (
    credentials: PublicAlbumsCredentials | undefined,
) => {
    publicAlbumsCredentials = credentials;
};
