import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Overlay } from "@/base/components/mui/Container";
import React from "react";

/**
 * An opaque overlay that covers the entire viewport and shows an activity
 * indicator in its center.
 *
 * Useful as a top level "blocking" overscreen while the app is being loaded.
 */
export const LoadingOverlay: React.FC = () => (
    <Overlay
        sx={(theme) => ({
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 2000,
            backgroundColor: theme.colors.background.base,
        })}
    >
        <ActivityIndicator />
    </Overlay>
);
