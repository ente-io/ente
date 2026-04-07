import { CustomHeadShare } from "ente-base/components/Head";
import React, { useEffect, useState } from "react";
import { CollectionShareView } from "../components/file-share/CollectionShareView";
import { FileShareView } from "../components/file-share/FileShareView";

const detectShareView = (): "file" | "collection" | null => {
    if (typeof window === "undefined") {
        return null;
    }

    const pathname = window.location.pathname;

    if (/^\/c\/[^/]+\/?$/.test(pathname)) {
        return "collection";
    }

    if (pathname === "/" || pathname === "") {
        return null;
    }

    return "file";
};

/**
 * Index page that handles root redirect, single-file share links, and
 * locker collection share links.
 *
 * - Root domain (/) redirects to ente.com/locker
 * - Single-file share links (/{token}#{key}) render FileShareView
 * - Collection share links (/c/{token}#{collectionKey}) render CollectionShareView
 *
 * This page is served for all routes via:
 * - _redirects file for Cloudflare Pages
 * - Next.js rewrites for local development
 * - nginx try_files for Docker deployment
 */
const Page: React.FC = () => {
    const [hideContent, setHideContent] = useState(false);
    const [shareView, setShareView] = useState<"file" | "collection" | null>(
        null,
    );

    useEffect(() => {
        const pathname = window.location.pathname;
        setShareView(detectShareView());

        if (pathname === "/" || pathname === "") {
            setHideContent(true);
            window.location.href = "https://ente.com/locker";
            return;
        }
    }, []);

    return (
        <>
            <CustomHeadShare title="Ente Locker" />
            {!hideContent &&
                shareView &&
                (shareView === "collection" ? (
                    <CollectionShareView />
                ) : (
                    <FileShareView />
                ))}
        </>
    );
};

export default Page;
