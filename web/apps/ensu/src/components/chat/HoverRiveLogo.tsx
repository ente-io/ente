import { Box } from "@mui/material";
import { useRouter } from "next/router";
import React, { memo, useEffect, useRef, useState } from "react";

type HoverRiveLogoProps = {
    staticSrc: string;
    alt: string;
    sizePx?: number;
};

type RiveInstance = {
    cleanup?: () => void;
    resizeDrawingSurfaceToCanvas?: () => void;
    play?: () => void;
    pause?: () => void;
    stop?: () => void;
    reset?: () => void;
};

const RIVE_SRC = "/animations/ensu.riv";

const HoverRiveLogo = memo(
    ({ staticSrc, alt, sizePx = 28 }: HoverRiveLogoProps) => {
        const canvasRef = useRef<HTMLCanvasElement | null>(null);
        const riveRef = useRef<RiveInstance | null>(null);
        const [isHovering, setIsHovering] = useState(false);
        const [isReady, setIsReady] = useState(false);
        const [failedToLoad, setFailedToLoad] = useState(false);
        const { basePath } = useRouter();
        const riveSrc = `${basePath ?? ""}${RIVE_SRC}`;

        useEffect(() => {
            if (typeof window === "undefined") return;

            let canceled = false;

            const initialize = async () => {
                try {
                    const rive = await import("@rive-app/canvas");
                    if (canceled || !canvasRef.current) return;

                    const { Alignment, Fit, Layout, Rive } = rive;
                    riveRef.current = new Rive({
                        src: riveSrc,
                        canvas: canvasRef.current,
                        autoplay: false,
                        layout: new Layout({
                            fit: Fit.Contain,
                            alignment: Alignment.Center,
                        }),
                        onLoad: () => {
                            try {
                                riveRef.current?.resizeDrawingSurfaceToCanvas?.();
                                riveRef.current?.pause?.();
                            } catch {
                                // noop
                            }
                            if (!canceled) {
                                setIsReady(true);
                            }
                        },
                        onLoadError: () => {
                            if (!canceled) {
                                setFailedToLoad(true);
                            }
                        },
                    });
                } catch {
                    if (!canceled) {
                        setFailedToLoad(true);
                    }
                }
            };

            void initialize();

            return () => {
                canceled = true;
                try {
                    riveRef.current?.cleanup?.();
                } catch {
                    // noop
                }
                riveRef.current = null;
            };
        }, [riveSrc]);

        const startAnimation = () => {
            setIsHovering(true);
            try {
                riveRef.current?.reset?.();
                riveRef.current?.play?.();
            } catch {
                // noop
            }
        };

        const stopAnimation = () => {
            setIsHovering(false);
            try {
                riveRef.current?.pause?.();
                riveRef.current?.stop?.();
            } catch {
                // noop
            }
        };

        const showRive = isHovering && isReady && !failedToLoad;

        return (
            <Box
                onMouseEnter={startAnimation}
                onMouseLeave={stopAnimation}
                sx={{
                    position: "relative",
                    width: sizePx,
                    height: sizePx,
                    display: "inline-flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexShrink: 0,
                }}
            >
                <Box
                    component="img"
                    src={staticSrc}
                    alt={alt}
                    sx={{
                        width: "100%",
                        height: "100%",
                        display: "block",
                        opacity: showRive ? 0 : 1,
                        transition: "opacity 120ms ease-out",
                    }}
                />
                <Box
                    component="canvas"
                    ref={canvasRef}
                    width={sizePx}
                    height={sizePx}
                    aria-label={`${alt} animation`}
                    sx={{
                        position: "absolute",
                        inset: 0,
                        width: "100%",
                        height: "100%",
                        display: showRive ? "block" : "none",
                    }}
                />
            </Box>
        );
    },
);

HoverRiveLogo.displayName = "HoverRiveLogo";

export default HoverRiveLogo;
