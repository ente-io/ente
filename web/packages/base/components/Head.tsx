import Head from "next/head";
import React from "react";

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
