import { Box, Typography } from "@mui/material";
import { useRouter } from "next/router";
import { memo, useEffect, useRef, useState } from "react";

type GeneratingRiveIndicatorProps = {
    size?: number;
    fallbackText?: string;
    isGenerating?: boolean;
    isOutroPhase?: boolean;
};

type RivePlaybackTarget = string | string[];

type RiveInput = { name?: string; value?: boolean | number; fire?: () => void };

type RiveInstance = {
    cleanup?: () => void;
    resizeDrawingSurfaceToCanvas?: () => void;
    play?: (animation?: RivePlaybackTarget) => void;
    pause?: () => void;
    stop?: () => void;
    animationNames?: string[];
    stateMachineNames?: string[];
    stateMachineInputs?: (stateMachineName: string) => RiveInput[];
};

const RIVE_SRC = "/animations/ensu.riv";

const GeneratingRiveIndicator = memo(
    ({
        size = 42,
        fallbackText,
        isGenerating = true,
        isOutroPhase = false,
    }: GeneratingRiveIndicatorProps) => {
        const canvasRef = useRef<HTMLCanvasElement | null>(null);
        const instanceRef = useRef<RiveInstance | null>(null);
        const playbackTargetRef = useRef<RivePlaybackTarget | undefined>(
            undefined,
        );
        const outroInputRef = useRef<RiveInput | null>(null);
        const outroNamedTargetRef = useRef<string | undefined>(undefined);
        const wasGeneratingRef = useRef(isGenerating);
        const wasOutroPhaseRef = useRef(isOutroPhase);
        const generatingLiveRef = useRef(isGenerating);
        const outroPhaseLiveRef = useRef(isOutroPhase);
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
            const instance = instanceRef.current;
            if (!instance) return;

            const outroInput = outroInputRef.current;
            if (outroInput) {
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
                    return;
                }
            }

            const outroNamedTarget = outroNamedTargetRef.current;
            if (outroNamedTarget) {
                instance.pause?.();
                instance.stop?.();
                instance.play?.(outroNamedTarget);
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

                                const stateMachineName = stateMachineNames[0];
                                if (stateMachineName) {
                                    playbackTargetRef.current =
                                        stateMachineName;
                                    const inputs =
                                        instance?.stateMachineInputs?.(
                                            stateMachineName,
                                        ) ?? [];
                                    outroInputRef.current =
                                        inputs.find((input) =>
                                            input.name
                                                ?.toLowerCase()
                                                .includes("outro"),
                                        ) ?? null;

                                    if (
                                        outroInputRef.current &&
                                        typeof outroInputRef.current.value ===
                                            "boolean"
                                    ) {
                                        outroInputRef.current.value = false;
                                    }
                                    if (
                                        outroInputRef.current &&
                                        typeof outroInputRef.current.value ===
                                            "number"
                                    ) {
                                        outroInputRef.current.value = 0;
                                    }
                                } else if (animationNames.length > 1) {
                                    playbackTargetRef.current = animationNames;
                                } else if (animationNames.length === 1) {
                                    playbackTargetRef.current =
                                        animationNames[0];
                                }

                                outroNamedTargetRef.current = [
                                    ...stateMachineNames,
                                    ...animationNames,
                                ].find((name) =>
                                    name.toLowerCase().includes("outro"),
                                );

                                playMain();
                            } catch {
                                // noop
                            }
                        },
                        onStop: () => {
                            try {
                                if (
                                    generatingLiveRef.current &&
                                    !outroPhaseLiveRef.current
                                ) {
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
                outroNamedTargetRef.current = undefined;
            };
        }, [riveSrc]);

        useEffect(() => {
            const wasGenerating = wasGeneratingRef.current;
            const wasOutroPhase = wasOutroPhaseRef.current;

            generatingLiveRef.current = isGenerating;
            outroPhaseLiveRef.current = isOutroPhase;

            if (!wasOutroPhase && isOutroPhase) {
                triggerOutro();
            }

            if (!isOutroPhase && isGenerating && !wasGenerating) {
                playMain();
            }

            wasGeneratingRef.current = isGenerating;
            wasOutroPhaseRef.current = isOutroPhase;
        }, [isGenerating, isOutroPhase]);

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
                    display: "flex",
                    alignItems: "center",
                    overflow: "hidden",
                    maxHeight: size,
                    opacity: 1,
                }}
            >
                <Box
                    component="canvas"
                    ref={canvasRef}
                    width={size}
                    height={size}
                    aria-label="Generating response animation"
                    sx={{ width: size, height: size, display: "block" }}
                />
            </Box>
        );
    },
);

GeneratingRiveIndicator.displayName = "GeneratingRiveIndicator";

export default GeneratingRiveIndicator;
