import React from "react";
import { FileShareView } from "../components/file-share/FileShareView";

/**
 * 404 page that handles all share links with the format:
 * /4MzPEanZK8#FvDZiMigvQ8Qwh813CFUL1E2szXovnxwNoViEUpdfngE
 *
 * This page is served by static hosts (Cloudflare Pages, self-hosted servers)
 * when no matching file exists for a path. The token is extracted from the
 * pathname and the key from the hash fragment.
 *
 * This approach works without server configuration files (_redirects, etc.)
 * because static hosts automatically serve 404.html for unmatched routes
 * while preserving the URL in the browser.
 */
const NotFoundPage: React.FC = () => {
    return <FileShareView />;
};

export default NotFoundPage;
