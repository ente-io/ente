import { Overlay, Stack100vhCenter } from "@/base/components/containers";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import React from "react";

/**
 * A centered activity indicator shown in a container that fills up the entire
 * width and height of the viewport.
 *
 * This is meant as a root component of a page, e.g., during initial load.
 */
export const LoadingIndicator: React.FC = () => (
    <Stack100vhCenter>
        <ActivityIndicator />
    </Stack100vhCenter>
);

/**
 * An opaque overlay that covers the entire viewport and shows an activity
 * indicator in its center.
 *
 * Useful as a top level "blocking" overscreen while the app is being loaded.
 */
export const LoadingOverlay: React.FC = () => (
    <Overlay
        sx={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 2000,
            backgroundColor: "background.default",
        }}
    >
        <ActivityIndicator />
    </Overlay>
);

/**
 * An translucent overlay that covers the entire viewport and shows an activity
 * indicator in its center.
 *
 * Used as a overscreen during blocking actions.
 */
export const TranslucentLoadingOverlay: React.FC = () => (
    <Overlay
        sx={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 9000,
            backgroundColor: "backdrop.muted",
        }}
    >
        <ActivityIndicator />
    </Overlay>
);
