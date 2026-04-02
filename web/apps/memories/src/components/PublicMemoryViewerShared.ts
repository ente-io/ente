import { styled } from "@mui/material";
import type { EnteFile } from "ente-media/file";
import type {
    PublicMemoryShareFrame,
    PublicMemoryShareMetadata,
} from "../services/public-memory";

export interface PublicMemoryViewerBaseProps {
    files: EnteFile[];
    currentIndex: number;
    memoryName: string;
    onNext: () => void;
    onPrev: () => void;
    onSeek: (index: number) => void;
}

export interface LaneMemoryViewerProps extends PublicMemoryViewerBaseProps {
    memoryMetadata?: PublicMemoryShareMetadata;
    laneFrames?: (PublicMemoryShareFrame | undefined)[];
}

export type MemoryViewerProps = PublicMemoryViewerBaseProps;

export const IMAGE_AUTO_PROGRESS_DURATION_MS = 5000;
export const MOBILE_LAYOUT_BREAKPOINT_PX = 600;
export const EDGE_NAV_TAP_ZONE_RATIO = 0.2;
export const HOLD_TO_PAUSE_NAV_SUPPRESSION_MS = 250;
export const ENTE_BRAND_TAG_IMAGE_PATH = "/images/ente-brand-tag.svg";

export function readViewport() {
    return {
        width: window.visualViewport?.width ?? window.innerWidth,
        height: window.visualViewport?.height ?? window.innerHeight,
    };
}

export function isInteractiveTapTarget(target: EventTarget | null) {
    if (!(target instanceof Element)) {
        return false;
    }

    return Boolean(
        target.closest(
            "button, a, input, textarea, select, [role='button'], [data-memory-control='true']",
        ),
    );
}

export const ViewerRoot = styled("div")({
    position: "relative",
    width: "100vw",
    minHeight: "100svh",
    height: "100dvh",
    overflow: "hidden",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    userSelect: "none",
    WebkitUserSelect: "none",
    WebkitTouchCallout: "none",
    WebkitTapHighlightColor: "transparent",
    touchAction: "manipulation",
});

export const BrandLink = styled("a")({
    color: "inherit",
    textDecoration: "none",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
});

export const EnteBrandTagImage = styled("img")({
    width: "76px",
    height: "auto",
    display: "block",
    userSelect: "none",
});

export const JoinNowButton = styled("a")({
    backgroundColor: "#08c225",
    color: "white",
    textDecoration: "none",
    borderRadius: "39px",
    padding: "18px 32px",
    fontWeight: 700,
    fontSize: "16px",
    lineHeight: "14px",
    whiteSpace: "nowrap",
    transition: "filter 150ms ease",
    "&:hover": { filter: "brightness(1.08)" },
    "@media (max-width: 900px)": { padding: "14px 24px", fontSize: "14px" },
});

export const MobileJoinNowButton = styled("a")({
    backgroundColor: "#08c225",
    color: "white",
    textDecoration: "none",
    borderRadius: "33px",
    padding: "16px 28px",
    fontWeight: 700,
    fontSize: "14px",
    lineHeight: "12px",
    whiteSpace: "nowrap",
});

export const ViewerFooterBar = styled("div")({
    width: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "10px",
    marginTop: "auto",
    paddingBottom: "max(2px, env(safe-area-inset-bottom, 0px))",
});

export const PhotoContainer = styled("div")({
    position: "relative",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flex: 1,
    minHeight: 0,
    width: "100%",
    cursor: "pointer",
    userSelect: "none",
    WebkitUserSelect: "none",
    WebkitTouchCallout: "none",
    touchAction: "manipulation",
});
