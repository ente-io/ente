import Head from "next/head";
import React from "react";
import { haveWindow } from "../env";
import {
    albumsAppOrigin,
    isCustomAlbumsAppOrigin,
    isCustomShareAppOrigin,
    shareAppOrigin,
} from "../origins";

interface CustomHeadProps {
    title: string;
}

/**
 * A custom version of "next/head" that sets the title, description, favicon and
 * some other boilerplate <head> tags.
 *
 * This assumes the existence of `public/images/favicon.png`.
 */
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

/**
 * A static SSR-ed variant of {@link CustomHead} for use with the albums app
 * deployed on production Ente instances for link previews.
 *
 * In particular,
 *
 * - Any client side modifications to the document's head will be too late for
 *   use by the link previews, so the contents of this need to part of the
 *   static HTML.
 *
 * - "og:image" needs to be an absolute URL.
 *
 * To avoid getting in the way of self hosters, we do a deployment URL check
 * before inlining this into the build.
 */
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
        {/* Twitter wants its own thing. */}
        <meta
            name="twitter:image"
            content="https://albums.ente.io/images/preview.jpg"
        />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="referrer" content="strict-origin-when-cross-origin" />
    </Head>
);

/**
 * A convenience fan out to conditionally show one of {@link CustomHead} or
 * {@link CustomHeadAlbums}.
 *
 * 1. This component defaults to {@link CustomHeadAlbums} during SSR unless a
 *    custom endpoint is defined.
 *
 * 2. Currently the photos and albums app use the same code. During SSR this
 *    uses the albums variant, and then does a client side update to the photos
 *    head when it detects that the origin it is being served on is not the
 *    albums origin.
 *
 * The current content of the head is such that it sort of works for both photos
 * and public albums, so the client side update is just an enhancement. We
 * should not need this component when the photos and public albums app split.
 */
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

/**
 * A static SSR-ed variant of {@link CustomHead} for use with the share app
 * (Public Locker) deployed on production Ente instances for link previews.
 *
 * Similar to {@link CustomHeadAlbums}, this includes Open Graph meta tags with
 * absolute URLs for social media preview images.
 */
export const CustomHeadShareStatic: React.FC = () => (
    <Head>
        <title>Ente Locker</title>
        <link rel="icon" href="/images/favicon.png" type="image/png" />
        <meta
            name="description"
            content="Securely store and share your documents"
        />
        <meta
            property="og:image"
            content="https://share.ente.io/images/preview.png"
        />
        <meta
            name="twitter:image"
            content="https://share.ente.io/images/preview.png"
        />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="referrer" content="strict-origin-when-cross-origin" />
    </Head>
);

/**
 * A convenience fan out to conditionally show one of {@link CustomHead} or
 * {@link CustomHeadShareStatic}.
 *
 * This component defaults to {@link CustomHeadShareStatic} during SSR unless a
 * custom endpoint is defined, and then does a client side update when it
 * detects that the origin it is being served on is not the share origin.
 */
export const CustomHeadShare: React.FC<CustomHeadProps> = ({ title }) =>
    isCustomShareAppOrigin ||
    (haveWindow() &&
        new URL(window.location.href).origin != shareAppOrigin()) ? (
        <CustomHead {...{ title }} />
    ) : (
        <CustomHeadShareStatic />
    );
