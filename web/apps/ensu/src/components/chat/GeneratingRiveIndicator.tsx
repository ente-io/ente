import { Box, Typography } from "@mui/material";
import { useRouter } from "next/router";
import React, { memo, useEffect, useRef, useState } from "react";

type GeneratingRiveIndicatorProps = {
    size?: number;
    fallbackText?: string;
};

type RivePlaybackTarget = string | string[];

type RiveInstance = {
    cleanup?: () => void;
    resizeDrawingSurfaceToCanvas?: () => void;
    play?: (animation?: RivePlaybackTarget) => void;
    animationNames?: string[];
    stateMachineNames?: string[];
};

const RIVE_SRC = "/animations/ensu.riv";

const GeneratingRiveIndicator = memo(
    ({ size = 42, fallbackText }: GeneratingRiveIndicatorProps) => {
        const canvasRef = useRef<HTMLCanvasElement | null>(null);
        const [failedToLoad, setFailedToLoad] = useState(false);
        const { basePath } = useRouter();
        const riveSrc = `${basePath ?? ""}${RIVE_SRC}`;

        useEffect(() => {
            if (typeof window === "undefined") return;

            let canceled = false;
            let instance: RiveInstance | null = null;
            let playbackTarget: RivePlaybackTarget | undefined;

            const initialize = async () => {
                try {
                    const rive = await import("@rive-app/canvas");
                    if (canceled || !canvasRef.current) {
                        return;
                    }

                    const { Alignment, Fit, Layout, Rive } = rive;
                    instance = new Rive({
                        src: riveSrc,
                        canvas: canvasRef.current,
                        autoplay: false,
                        layout: new Layout({
                            fit: Fit.Contain,
                            alignment: Alignment.Center,
                        }),
                        onLoad: () => {
                            try {
                                instance?.resizeDrawingSurfaceToCanvas?.();
                                const stateMachineNames =
                                    instance?.stateMachineNames ?? [];
                                const animationNames =
                                    instance?.animationNames ?? [];

                                if (stateMachineNames.length > 0) {
                                    playbackTarget = stateMachineNames[0];
                                } else if (animationNames.length > 1) {
                                    playbackTarget = animationNames;
                                } else if (animationNames.length === 1) {
                                    playbackTarget = animationNames[0];
                                }

                                if (playbackTarget) {
                                    instance?.play?.(playbackTarget);
                                } else {
                                    instance?.play?.();
                                }
                            } catch {
                                // noop
                            }
                        },
                        onStop: () => {
                            try {
                                if (playbackTarget) {
                                    instance?.play?.(playbackTarget);
                                } else {
                                    instance?.play?.();
                                }
                            } catch {
                                // noop
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
                    instance?.cleanup?.();
                } catch {
                    // noop
                }
            };
        }, [riveSrc]);

        if (failedToLoad) {
            return (
                <Typography
                    variant="message"
                    sx={{ color: "text.muted", whiteSpace: "pre-wrap" }}
                >
                    {fallbackText ?? "Generating your reply"}
                </Typography>
            );
        }

        return (
            <Box
                sx={{
                    minHeight: size,
                    display: "flex",
                    alignItems: "center",
                }}
            >
                <Box
                    component="canvas"
                    ref={canvasRef}
                    width={size}
                    height={size}
                    aria-label="Generating response animation"
                    sx={{
                        width: size,
                        height: size,
                        display: "block",
                    }}
                />
            </Box>
        );
    },
);

GeneratingRiveIndicator.displayName = "GeneratingRiveIndicator";

export default GeneratingRiveIndicator;
