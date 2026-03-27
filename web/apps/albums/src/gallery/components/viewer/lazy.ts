import dynamic from "next/dynamic";
import type { FileViewerProps } from "./FileViewer";
import type { PublicFeedSidebarProps } from "./PublicFeedSidebar";

export const LazyFileViewer = dynamic<FileViewerProps>(
    () => import("./FileViewer").then(({ FileViewer }) => FileViewer),
    { ssr: false },
);

export const LazyPublicFeedSidebar = dynamic<PublicFeedSidebarProps>(
    () =>
        import("./PublicFeedSidebar").then(
            ({ PublicFeedSidebar }) => PublicFeedSidebar,
        ),
    { ssr: false },
);
