import dynamic from "next/dynamic";
import {
    PublicMemoryEmptyState,
    PublicMemoryErrorState,
    PublicMemoryLoadingContent,
    PublicMemoryLoadingState,
    PublicMemoryPageShell,
} from "../components/PublicMemoryPageShell";
import type {
    LaneMemoryViewerProps,
    MemoryViewerProps,
} from "../components/PublicMemoryViewerShared";
import { usePublicMemoryPage } from "../hooks/usePublicMemoryPage";

function ViewerChunkLoadingFallback() {
    return <PublicMemoryLoadingContent />;
}

const LaneMemoryViewer = dynamic<LaneMemoryViewerProps>(
    () =>
        import("../components/LaneMemoryViewer").then(
            (module) => module.LaneMemoryViewer,
        ),
    { loading: ViewerChunkLoadingFallback },
);

const MemoryViewer = dynamic<MemoryViewerProps>(
    () =>
        import("../components/MemoryViewer").then(
            (module) => module.MemoryViewer,
        ),
    { loading: ViewerChunkLoadingFallback },
);

/**
 * Index page that handles both root redirect and memory share links
 *
 * - Root domain (/) redirects to the configured memories landing page
 * - Share links (/TOKEN#key) render the memory viewer
 *
 * This page is served for all routes via:
 * - _redirects file for Cloudflare Pages
 * - Next.js rewrites for local development
 * - nginx try_files for Docker deployment
 */
export default function PublicMemoryPage() {
    const {
        currentIndex,
        errorMessage,
        files,
        goToNext,
        goToPrev,
        handleSeek,
        hideContent,
        laneFrames,
        loading,
        memoryMetadata,
        memoryName,
        viewerVariant,
    } = usePublicMemoryPage();

    if (hideContent) {
        return <PublicMemoryPageShell />;
    }

    if (loading) {
        return <PublicMemoryLoadingState />;
    }

    if (errorMessage) {
        return <PublicMemoryErrorState message={errorMessage} />;
    }

    if (!files || files.length === 0) {
        return <PublicMemoryEmptyState />;
    }

    const sharedViewerProps: MemoryViewerProps = {
        files,
        currentIndex,
        memoryName,
        onNext: goToNext,
        onPrev: goToPrev,
        onSeek: handleSeek,
    };

    const laneViewerProps: LaneMemoryViewerProps = {
        ...sharedViewerProps,
        memoryMetadata,
        laneFrames,
    };

    return (
        <PublicMemoryPageShell>
            {viewerVariant === "lane" ? (
                <LaneMemoryViewer {...laneViewerProps} />
            ) : (
                <MemoryViewer {...sharedViewerProps} />
            )}
        </PublicMemoryPageShell>
    );
}
