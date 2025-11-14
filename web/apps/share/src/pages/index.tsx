import { CustomHeadShare } from "ente-base/components/Head";
import React, { useEffect, useState } from "react";
import { FileShareView } from "../components/file-share/FileShareView";

/**
 * Index page that handles both root redirect and share links
 *
 * - Root domain (/) redirects to ente.io/locker
 * - Share links (/token#key) render the FileShareView
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
            // Redirect to ente.io/locker for root path
            window.location.href = "https://ente.io/locker";
        }
    }, []);

    // Always render CustomHeadShare for SSR (ensures meta tags are in static HTML)
    return (
        <>
            <CustomHeadShare title="Ente Locker" />
            {/* Hide FileShareView only when we detect root path on client */}
            {!hideContent && <FileShareView />}
        </>
    );
};

export default Page;
