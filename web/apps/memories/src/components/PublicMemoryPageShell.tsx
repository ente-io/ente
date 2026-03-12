import { Typography } from "@mui/material";
import { Stack100vhCenter } from "ente-base/components/containers";
import { CustomHead } from "ente-base/components/Head";
import { LoadingIndicator } from "ente-base/components/loaders";
import Head from "next/head";
import type { PropsWithChildren } from "react";

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

export function PublicMemoryPageShell({ children }: PropsWithChildren) {
    return (
        <>
            <PublicMemoryDocumentHead />
            {children}
        </>
    );
}

export function PublicMemoryLoadingState() {
    return (
        <PublicMemoryPageShell>
            <LoadingIndicator />
        </PublicMemoryPageShell>
    );
}

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

export function PublicMemoryEmptyState() {
    return (
        <PublicMemoryPageShell>
            <Stack100vhCenter>
                <Typography>No photos found in this memory.</Typography>
            </Stack100vhCenter>
        </PublicMemoryPageShell>
    );
}
