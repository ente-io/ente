import { CustomHeadPhotosShare } from "ente-base/components/Head";
import React, { useEffect, useState } from "react";
import { PhotoShareView } from "../components/PhotoShareView";

/**
 * Index page that handles both root redirect and share links
 *
 * - Root domain (/) redirects to ente.io/photos
 * - Share links (/token#key) render the PhotoShareView
 *
 * This page is served for all routes via:
 * - _redirects file for Cloudflare Pages
 * - Next.js rewrites for local development
 * - nginx try_files for Docker deployment
 */
const Page: React.FC = () => {
    const [hideContent, setHideContent] = useState(false);

    useEffect(() => {
        // Check if we're at the root path (client-side only)
        const pathname = window.location.pathname;

        if (pathname === "/" || pathname === "") {
            // Hide content before redirect to avoid error flash
            setHideContent(true);
            // Redirect to ente.io/photos for root path
            window.location.href = "https://ente.io/photos";
        }
    }, []);

    // Always render CustomHeadPhotosShare for SSR (ensures meta tags are in static HTML)
    return (
        <>
            <CustomHeadPhotosShare title="Ente Photos" />
            {/* Hide PhotoShareView only when we detect root path on client */}
            {!hideContent && <PhotoShareView />}
        </>
    );
};

export default Page;
