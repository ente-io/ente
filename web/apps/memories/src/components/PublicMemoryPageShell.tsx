/**
 * Shared page shell and top-level fallback states for the public memories flow.
 * This file defines the document head wrapper plus the loading, error, and
 * empty states used by `pages/index.tsx` before a viewer is rendered.
 */
import { CircularProgress, Typography } from "@mui/material";
import { Stack100vhCenter } from "ente-base/components/containers";
import { CustomHead } from "ente-base/components/Head";
import Head from "next/head";
import type { PropsWithChildren } from "react";

/**
 * Injects shared metadata for every public memory page.
 * Used only by `PublicMemoryPageShell` in this file.
 */
function PublicMemoryDocumentHead() {
    return (
        <>
            <CustomHead title="Ente Memories" />
            <Head>
                <meta name="robots" content="noindex, nofollow" />
            </Head>
        </>
    );
}

/**
 * Wraps every public memory screen with the shared head metadata.
 * Used by `pages/index.tsx` and by the loading/error/empty state helpers below.
 */
export function PublicMemoryPageShell({ children }: PropsWithChildren) {
    return (
        <>
            <PublicMemoryDocumentHead />
            {children}
        </>
    );
}

/**
 * Full-screen loading state shown while `usePublicMemoryPage` is resolving the share.
 * Used by `pages/index.tsx`.
 */
export function PublicMemoryLoadingState() {
    return (
        <PublicMemoryPageShell>
            <Stack100vhCenter sx={{ minHeight: "100dvh" }}>
                <CircularProgress sx={{ color: "#08c225" }} size={32} />
            </Stack100vhCenter>
        </PublicMemoryPageShell>
    );
}

/**
 * Full-screen error state for invalid, expired, or failed public memory loads.
 * Used by `pages/index.tsx`.
 */
export function PublicMemoryErrorState({ message }: { message: string }) {
    return (
        <PublicMemoryPageShell>
            <Stack100vhCenter>
                <Typography sx={{ color: "critical.main" }}>
                    {message}
                </Typography>
            </Stack100vhCenter>
        </PublicMemoryPageShell>
    );
}

/**
 * Full-screen empty state for shares that resolve without any files.
 * Used by `pages/index.tsx`.
 */
export function PublicMemoryEmptyState() {
    return (
        <PublicMemoryPageShell>
            <Stack100vhCenter>
                <Typography>No photos found in this memory.</Typography>
            </Stack100vhCenter>
        </PublicMemoryPageShell>
    );
}
