import Head from "next/head";
import React from "react";
import { haveWindow } from "../env";
import { albumsAppOrigin, isCustomAlbumsAppOrigin } from "../origins";

interface CustomHeadProps {
    title: string;
}

export const CustomHead: React.FC<CustomHeadProps> = ({ title }) => (
    <Head>
        <title>{title}</title>
        <link rel="icon" href="/images/favicon.png" type="image/png" />
        <meta
            name="description"
            content="Ente - end-to-end encrypted cloud with open-source apps"
        />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="referrer" content="strict-origin-when-cross-origin" />
    </Head>
);

export const CustomHeadAlbums: React.FC = () => (
    <Head>
        <title>Ente Photos</title>
        <link rel="icon" href="/images/favicon.png" type="image/png" />
        <meta
            name="description"
            content="Safely store and share your best moments"
        />
        <meta
            property="og:image"
            content="https://albums.ente.io/images/preview.jpg"
        />
        <meta
            name="twitter:image"
            content="https://albums.ente.io/images/preview.jpg"
        />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="referrer" content="strict-origin-when-cross-origin" />
    </Head>
);

export const CustomHeadPhotosOrAlbums: React.FC<CustomHeadProps> = ({
    title,
}) =>
    isCustomAlbumsAppOrigin ||
    (haveWindow() &&
        new URL(window.location.href).origin != albumsAppOrigin()) ? (
        <CustomHead {...{ title }} />
    ) : (
        <CustomHeadAlbums />
    );
