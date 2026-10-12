import { Box } from "@mui/material";
import type { Rive, ViewModelInstance } from "@rive-app/canvas-lite";
import {
    likeAnimationVariants,
    pickLikeVariant,
} from "components/post-like-animation";
import log from "ente-base/log";
import React from "react";

// Shows the liked or unliked state without animating.
const jumpVariant = -1;
const likeAnimationMs = 1600;
// The 160px artboard draws a 22px heart; scale it to the 26px icon it replaces.
const canvasSize = Math.round((160 * 26) / 22);

let likeFile: Promise<ArrayBuffer> | undefined;
const loadLikeFile = () => {
    if (!likeFile) {
        likeFile = fetch("/images/like.riv").then((response) => {
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return response.arrayBuffer();
        });
        void likeFile.catch(() => {
            likeFile = undefined;
        });
    }
    return likeFile;
};

interface SpacePostLikeHeartProps {
    liked: boolean;
    // Changes on each like or unlike. Other changes of liked do not animate.
    toggleID: number;
    fallback: React.ReactNode;
}

export const SpacePostLikeHeart: React.FC<SpacePostLikeHeartProps> = ({
    liked,
    toggleID,
    fallback,
}) => {
    const canvasRef = React.useRef<HTMLCanvasElement | null>(null);
    const riveRef = React.useRef<Rive | undefined>(undefined);
    const pauseTimerRef = React.useRef(0);
    const shownRef = React.useRef({ liked, toggleID, variant: jumpVariant });
    const [viewModel, setViewModel] = React.useState<ViewModelInstance>();

    // Rive draws every frame while playing, so pause it when idle.
    const playFor = React.useCallback((ms: number) => {
        const rive = riveRef.current;
        if (!rive) return;
        window.clearTimeout(pauseTimerRef.current);
        rive.play();
        pauseTimerRef.current = window.setTimeout(() => rive.pause(), ms);
    }, []);

    React.useEffect(() => {
        const canvas = canvasRef.current;
        if (
            !canvas ||
            window.matchMedia("(prefers-reduced-motion: reduce)").matches
        )
            return;

        let disposed = false;
        void Promise.all([import("@rive-app/canvas-lite"), loadLikeFile()])
            .then(([{ Fit, Layout, Rive, RuntimeLoader }, file]) => {
                if (disposed) return;
                // The default is a public CDN, which the CSP blocks.
                RuntimeLoader.setWasmUrl(
                    new URL("@rive-app/canvas-lite/rive.wasm", import.meta.url)
                        .href,
                );
                RuntimeLoader.setWasmFallbackUrl(null);
                const rive = new Rive({
                    autoBind: true,
                    autoplay: true,
                    buffer: file.slice(0),
                    canvas,
                    enableRiveAssetCDN: false,
                    layout: new Layout({ fit: Fit.Contain }),
                    onLoad: () => {
                        if (disposed) return;
                        rive.resizeDrawingSurfaceToCanvas();
                        const instance = rive.viewModelInstance;
                        if (!instance) {
                            rive.cleanup();
                            riveRef.current = undefined;
                            return;
                        }
                        const variant = instance.number("variant");
                        const isLiked = instance.boolean("liked");
                        if (variant) variant.value = jumpVariant;
                        if (isLiked) isLiked.value = shownRef.current.liked;
                        playFor(150);
                        setViewModel(instance);
                    },
                    onLoadError: () =>
                        log.warn("Failed to load the like animation"),
                    stateMachine: "Like",
                });
                riveRef.current = rive;
            })
            .catch((error: unknown) => {
                log.warn("Failed to load the like animation", error);
            });
        return () => {
            disposed = true;
            window.clearTimeout(pauseTimerRef.current);
            riveRef.current?.cleanup();
            riveRef.current = undefined;
        };
    }, [playFor]);

    React.useEffect(() => {
        const shown = shownRef.current;
        if (viewModel) {
            const variant = viewModel.number("variant");
            const isLiked = viewModel.boolean("liked");
            const isToggle = toggleID != shown.toggleID;
            if (!isToggle) {
                if (variant) variant.value = jumpVariant;
            } else if (liked) {
                shown.variant = pickLikeVariant(shown.variant);
                if (variant) variant.value = shown.variant;
            } else if (variant && variant.value < 0) {
                // A jump would skip the unlike animation.
                variant.value = likeAnimationVariants[0]!;
            }
            if (isLiked) isLiked.value = liked;
            playFor(isToggle ? likeAnimationMs : 150);
        }
        shown.liked = liked;
        shown.toggleID = toggleID;
    }, [liked, toggleID, viewModel, playFor]);

    return (
        <Box
            component="span"
            sx={{ display: "flex", lineHeight: 0, position: "relative" }}
        >
            <Box
                component="span"
                sx={{
                    display: "flex",
                    visibility: viewModel ? "hidden" : "visible",
                }}
            >
                {fallback}
            </Box>
            <Box
                ref={canvasRef}
                component="canvas"
                aria-hidden
                sx={{
                    height: canvasSize,
                    left: "50%",
                    pointerEvents: "none",
                    position: "absolute",
                    top: "50%",
                    transform: "translate(-50%, -50%)",
                    visibility: viewModel ? "visible" : "hidden",
                    width: canvasSize,
                }}
            />
        </Box>
    );
};
