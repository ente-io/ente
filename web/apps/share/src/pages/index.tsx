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
    const [isShareLink, setIsShareLink] = useState<boolean | null>(null);

    useEffect(() => {
        // Check if we're at the root path
        const pathname = window.location.pathname;

        if (pathname === "/" || pathname === "") {
            // Redirect to ente.io/locker for root path
            window.location.href = "https://ente.io/locker";
        } else {
            // It's a share link, render the FileShareView
            setIsShareLink(true);
        }
    }, []);

    // Show nothing while determining the route
    if (isShareLink === null) {
        return null;
    }

    // Render the share view for share links
    return (
        <>
            <CustomHeadShare title="Ente Locker" />
            <FileShareView />
        </>
    );
};

export default Page;
