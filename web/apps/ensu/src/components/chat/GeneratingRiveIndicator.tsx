import { Box, Typography } from "@mui/material";
import { useRouter } from "next/router";
import React, { memo, useEffect, useRef, useState } from "react";

type GeneratingRiveIndicatorProps = {
    size?: number;
    fallbackText?: string;
    isGenerating?: boolean;
};

type RivePlaybackTarget = string | string[];

type RiveInput = {
    name?: string;
    value?: boolean | number;
    fire?: () => void;
};

type RiveInstance = {
    cleanup?: () => void;
    resizeDrawingSurfaceToCanvas?: () => void;
    play?: (animation?: RivePlaybackTarget) => void;
    animationNames?: string[];
    stateMachineNames?: string[];
    stateMachineInputs?: (stateMachineName: string) => RiveInput[];
};

const RIVE_SRC = "/animations/ensu.riv";

const GeneratingRiveIndicator = memo(
    ({ size = 42, fallbackText, isGenerating = true }: GeneratingRiveIndicatorProps) => {
        const canvasRef = useRef<HTMLCanvasElement | null>(null);
        const instanceRef = useRef<RiveInstance | null>(null);
        const playbackTargetRef = useRef<RivePlaybackTarget | undefined>(undefined);
        const outroInputRef = useRef<RiveInput | null>(null);
        const wasGeneratingRef = useRef(isGenerating);
        const [failedToLoad, setFailedToLoad] = useState(false);
        const { basePath } = useRouter();
        const riveSrc = `${basePath ?? ""}${RIVE_SRC}`;

        const playMain = () => {
            const instance = instanceRef.current;
            if (!instance) return;
            const target = playbackTargetRef.current;
            if (target) {
                instance.play?.(target);
            } else {
                instance.play?.();
            }
        };

        const triggerOutro = () => {
            const outroInput = outroInputRef.current;
            if (!outroInput) return;

            if (typeof outroInput.fire === "function") {
                outroInput.fire();
                return;
            }

            if (typeof outroInput.value === "boolean") {
                outroInput.value = true;
                return;
            }

            if (typeof outroInput.value === "number") {
                outroInput.value = 1;
            }
        };

        useEffect(() => {
            if (typeof window === "undefined") return;

            let canceled = false;

            const initialize = async () => {
                try {
                    const rive = await import("@rive-app/canvas");
                    if (canceled || !canvasRef.current) {
                        return;
                    }

                    const { Alignment, Fit, Layout, Rive } = rive;
                    instanceRef.current = new Rive({
                        src: riveSrc,
                        canvas: canvasRef.current,
                        autoplay: false,
                        layout: new Layout({
                            fit: Fit.Contain,
                            alignment: Alignment.Center,
                        }),
                        onLoad: () => {
                            try {
                                const instance = instanceRef.current;
                                instance?.resizeDrawingSurfaceToCanvas?.();

                                const stateMachineNames =
                                    instance?.stateMachineNames ?? [];
                                const animationNames =
                                    instance?.animationNames ?? [];

                                if (stateMachineNames.length > 0) {
                                    const stateMachineName = stateMachineNames[0];
                                    playbackTargetRef.current = stateMachineName;
                                    const inputs =
                                        instance?.stateMachineInputs?.(
                                            stateMachineName,
                                        ) ?? [];
                                    outroInputRef.current =
                                        inputs.find(
                                            (input) =>
                                                input.name?.toLowerCase() ===
                                                "outro",
                                        ) ?? null;
                                } else if (animationNames.length > 1) {
                                    playbackTargetRef.current = animationNames;
                                } else if (animationNames.length === 1) {
                                    playbackTargetRef.current = animationNames[0];
                                }

                                playMain();
                            } catch {
                                // noop
                            }
                        },
                        onStop: () => {
                            try {
                                if (wasGeneratingRef.current) {
                                    playMain();
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
                    instanceRef.current?.cleanup?.();
                } catch {
                    // noop
                }
                instanceRef.current = null;
                playbackTargetRef.current = undefined;
                outroInputRef.current = null;
            };
        }, [riveSrc]);

        useEffect(() => {
            const wasGenerating = wasGeneratingRef.current;

            if (wasGenerating && !isGenerating) {
                triggerOutro();
            }

            if (!wasGenerating && isGenerating) {
                playMain();
            }

            wasGeneratingRef.current = isGenerating;
        }, [isGenerating]);

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
