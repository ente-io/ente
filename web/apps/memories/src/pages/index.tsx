import { LaneMemoryViewer } from "../components/LaneMemoryViewer";
import { MemoryViewer } from "../components/MemoryViewer";
import {
    PublicMemoryEmptyState,
    PublicMemoryErrorState,
    PublicMemoryLoadingState,
    PublicMemoryPageShell,
} from "../components/PublicMemoryPageShell";
import { usePublicMemoryPage } from "../hooks/usePublicMemoryPage";

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

    const sharedViewerProps = {
        files,
        currentIndex,
        memoryName,
        memoryMetadata,
        laneFrames,
        onNext: goToNext,
        onPrev: goToPrev,
        onSeek: handleSeek,
    };

    return (
        <PublicMemoryPageShell>
            {viewerVariant === "lane" ? (
                <LaneMemoryViewer {...sharedViewerProps} />
            ) : (
                <MemoryViewer {...sharedViewerProps} variant={viewerVariant} />
            )}
        </PublicMemoryPageShell>
    );
}
