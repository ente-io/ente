import { keyframes } from "@emotion/react";
import { styled, useMediaQuery } from "@mui/material";
import {
    useEffect,
    useLayoutEffect,
    useRef,
    useState,
    type CSSProperties,
} from "react";
import { useTranslation } from "react-i18next";
import {
    laneCaptionNamePlaceholder,
    laneCaptionTimePlaceholder,
    localizeLaneCaption,
    type LaneCaptionModel,
} from "../utils/lane";

const glideOptions = {
    duration: 600,
    easing: "cubic-bezier(0.215, 0.61, 0.355, 1)",
};

interface CaptionPosition {
    x: number;
    y: number;
    width: number;
    height: number;
    text: string;
    numeric: boolean;
    element: HTMLElement;
    copy: HTMLElement;
}

export function LaneCaption({ model }: { model: LaneCaptionModel }) {
    const { t, i18n, ready } = useTranslation();
    const locale = i18n.language || "en-US";
    const caption = ready
        ? localizeLaneCaption(model, t, locale)
        : {
              template: model.text,
              language: "en-US",
              name: "",
              time: "",
              label: model.text,
              value: undefined,
              isNow: false,
          };
    const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
    const rootRef = useRef<HTMLDivElement>(null);
    const phraseRef = useRef<HTMLDivElement>(null);
    const positionsRef = useRef(new Map<string, CaptionPosition>());
    const animationsRef = useRef<Animation[]>([]);
    const ghostsRef = useRef<HTMLElement[]>([]);
    const [layoutVersion, setLayoutVersion] = useState(0);

    useEffect(() => {
        const root = rootRef.current;
        if (!root) return;
        const resetLayout = () => {
            positionsRef.current.clear();
            setLayoutVersion((value) => value + 1);
        };
        let width = root.getBoundingClientRect().width;
        const observer = new ResizeObserver(([entry]) => {
            if (!entry || Math.abs(entry.contentRect.width - width) < 0.5)
                return;
            width = entry.contentRect.width;
            resetLayout();
        });
        observer.observe(root);
        document.fonts.addEventListener("loadingdone", resetLayout);
        void document.fonts.load('22px "Gochi Hand"').catch(() => undefined);
        return () => {
            observer.disconnect();
            document.fonts.removeEventListener("loadingdone", resetLayout);
            animationsRef.current.forEach((animation) => animation.cancel());
            ghostsRef.current.forEach((ghost) => ghost.remove());
        };
    }, []);

    useLayoutEffect(() => {
        const root = rootRef.current;
        const phrase = phraseRef.current;
        if (!root || !phrase) return;
        const previous = positionsRef.current;
        for (const position of previous.values()) {
            const transform = getComputedStyle(position.element).transform;
            if (transform && transform !== "none") {
                const matrix = new DOMMatrixReadOnly(transform);
                position.x += matrix.m41;
                position.y += matrix.m42;
            }
        }
        animationsRef.current.forEach((animation) => animation.cancel());
        ghostsRef.current.forEach((ghost) => ghost.remove());
        animationsRef.current = [];
        ghostsRef.current = [];

        const elements = Array.from(
            phrase.querySelectorAll<HTMLElement>(":scope > [data-lane-part]"),
        );
        const bounds = root.getBoundingClientRect();
        const restWidth = elements.reduce(
            (sum, element) =>
                sum +
                (element.dataset.lanePart?.startsWith("name")
                    ? 0
                    : element.getBoundingClientRect().width),
            0,
        );
        for (const element of elements) {
            if (element.dataset.lanePart?.startsWith("name")) {
                element.style.maxWidth = `${Math.max(bounds.width * 0.35, bounds.width - restWidth)}px`;
            }
        }

        const next = new Map<string, CaptionPosition>();
        const animate = (element: HTMLElement, frames: Keyframe[]) => {
            const animation = element.animate(frames, glideOptions);
            animationsRef.current.push(animation);
        };
        const leave = (position: CaptionPosition, x: number, y: number) => {
            const ghost = position.copy;
            Object.assign(ghost.style, {
                position: "absolute",
                left: `${x}px`,
                top: `${y}px`,
                width: `${position.width}px`,
                height: `${position.height}px`,
                maxWidth: "none",
                overflow: "hidden",
                textOverflow: "ellipsis",
                margin: "0",
                pointerEvents: "none",
            });
            ghost.setAttribute("aria-hidden", "true");
            root.appendChild(ghost);
            ghostsRef.current.push(ghost);
            const animation = ghost.animate(
                [
                    { opacity: 1, filter: "blur(0)", transform: "scale(1)" },
                    {
                        opacity: 0,
                        filter: `blur(${position.numeric ? 4 : 1.5}px)`,
                        transform: `scale(${position.numeric ? 0.7 : 1})`,
                    },
                ],
                glideOptions,
            );
            animationsRef.current.push(animation);
            void animation.finished.then(
                () => ghost.remove(),
                () => ghost.remove(),
            );
        };

        for (const element of elements) {
            const key = element.dataset.lanePart!;
            const rect = element.getBoundingClientRect();
            const text = element.dataset.laneText ?? "";
            const numeric = element.dataset.laneNumeric === "true";
            const copy = element.cloneNode(false) as HTMLElement;
            copy.textContent = text;
            const position = {
                x: rect.left - bounds.left,
                y: rect.top - bounds.top,
                width: rect.width,
                height: rect.height,
                text,
                numeric,
                element,
                copy,
            };
            next.set(key, position);
            const before = previous.get(key);
            if (reducedMotion || !previous.size) continue;
            const changed =
                before?.text !== text && !(before?.numeric && numeric);
            const dx = before ? before.x - position.x : 0;
            const dy = before ? before.y - position.y : 0;
            if (changed && before) leave(before, before.x, before.y);
            animate(element, [
                {
                    transform: `translate(${dx}px, ${dy}px) scale(${changed && key.startsWith("time") ? 0.72 : 1})`,
                    opacity: changed ? 0 : 1,
                    filter: `blur(${changed ? (key.startsWith("time") ? 4 : 1.5) : 0}px)`,
                },
                { transform: "none", opacity: 1, filter: "blur(0)" },
            ]);
        }
        if (!reducedMotion) {
            for (const [key, position] of previous) {
                if (!next.has(key)) leave(position, position.x, position.y);
            }
        }
        positionsRef.current = next;
    }, [
        caption.template,
        caption.name,
        caption.time,
        caption.value,
        caption.language,
        locale,
        reducedMotion,
        layoutVersion,
    ]);

    let literal = 0;
    let names = 0;
    let times = 0;
    const parts = caption.template.split(/([\uFFF9\uFFFC])/u);
    return (
        <CaptionRoot
            ref={rootRef}
            lang={caption.language}
            dir={ready ? i18n.dir(caption.language) : "ltr"}
        >
            <AccessibleCaption>{caption.label}</AccessibleCaption>
            <div ref={phraseRef} aria-hidden="true">
                {parts.map((part) => {
                    if (!part) return null;
                    if (part === laneCaptionNamePlaceholder) {
                        const key = `name-${names++}`;
                        return (
                            <CaptionName
                                key={key}
                                data-lane-part={key}
                                data-lane-text={caption.name}
                                dir="auto"
                            >
                                <span>{caption.name}</span>
                            </CaptionName>
                        );
                    }
                    if (part === laneCaptionTimePlaceholder) {
                        const key = `time-${times++}`;
                        return (
                            <CaptionTime
                                key={key}
                                data-lane-part={key}
                                data-lane-text={caption.time}
                                data-lane-numeric={!caption.isNow}
                                className={caption.isNow ? "now" : undefined}
                                dir="auto"
                            >
                                {caption.value === undefined ? (
                                    caption.time
                                ) : (
                                    <RollingNumber
                                        value={caption.value}
                                        locale={locale}
                                        reducedMotion={reducedMotion}
                                    />
                                )}
                            </CaptionTime>
                        );
                    }
                    const key = `literal-${literal++}`;
                    return (
                        <CaptionPart
                            key={key}
                            data-lane-part={key}
                            data-lane-text={part}
                        >
                            {part}
                        </CaptionPart>
                    );
                })}
            </div>
        </CaptionRoot>
    );
}

function RollingNumber({
    value,
    locale,
    reducedMotion,
}: {
    value: number;
    locale: string;
    reducedMotion: boolean;
}) {
    const rootRef = useRef<HTMLSpanElement>(null);
    const widthsRef = useRef(new Map<number, number>());
    const [transition, setTransition] = useState({
        value,
        previous: value,
        widths: new Map<number, number>(),
    });
    if (value !== transition.value) {
        setTransition({
            value,
            previous: transition.value,
            widths: widthsRef.current,
        });
    }
    useLayoutEffect(() => {
        const root = rootRef.current;
        if (!root) return;
        const widths = new Map<number, number>();
        for (const digit of root.querySelectorAll<HTMLElement>(
            "[data-digit-current]",
        )) {
            widths.set(
                Number(digit.dataset.digitCurrent),
                Number.parseFloat(getComputedStyle(digit).width),
            );
        }
        widthsRef.current = widths;
        // Keep word layout at its destination while the outgoing digit shrinks.
        root.style.width = `${Array.from(widths.values()).reduce((sum, width) => sum + width, 0)}px`;
    });
    const formatter = new Intl.NumberFormat(locale);
    const current = Array.from(formatter.format(value));
    const previous = Array.from(formatter.format(transition.previous));
    const length = Math.max(current.length, previous.length);
    const direction = value >= transition.previous ? 1 : -1;
    return (
        <span ref={rootRef} dir="ltr" style={{ display: "inline-block" }}>
            {Array.from({ length }, (_, index) => {
                const place = length - index - 1;
                const digit = current[current.length - place - 1];
                const old = previous[previous.length - place - 1];
                if (reducedMotion || digit === old)
                    return (
                        <span
                            key={place}
                            data-digit-current={place}
                            style={{ display: "inline-block" }}
                        >
                            {digit}
                        </span>
                    );
                return (
                    <DigitWindow
                        key={place}
                        className={digit ? undefined : "disappearing"}
                        style={
                            {
                                "--digit-width": `${transition.widths.get(place) ?? 0}px`,
                            } as CSSProperties
                        }
                    >
                        <DigitLayer
                            key={`${value}-${locale}`}
                            data-digit-current={digit ? place : undefined}
                            style={
                                {
                                    "--roll-from": `${direction * 100}%`,
                                } as CSSProperties
                            }
                        >
                            {digit ?? "\u200b"}
                        </DigitLayer>
                        {old && (
                            <DigitLayer
                                key={`old-${value}-${locale}`}
                                className="outgoing"
                                style={
                                    {
                                        "--roll-to": `${-direction * 100}%`,
                                    } as CSSProperties
                                }
                            >
                                {old}
                            </DigitLayer>
                        )}
                    </DigitWindow>
                );
            })}
        </span>
    );
}

const CaptionRoot = styled("div")({
    position: "relative",
    width: "100%",
    minWidth: 0,
    color: "rgba(255, 255, 255, 0.7)",
    fontFamily: '"Inter Variable", Inter, sans-serif',
    fontWeight: 600,
    fontSize: "1rem",
    lineHeight: 1.25,
    textAlign: "center",
    overflowWrap: "anywhere",
});

const AccessibleCaption = styled("span")({
    position: "absolute",
    width: 1,
    height: 1,
    padding: 0,
    margin: -1,
    overflow: "hidden",
    clipPath: "inset(50%)",
    whiteSpace: "nowrap",
});

const CaptionPart = styled("span")({
    display: "inline-block",
    maxWidth: "100%",
    whiteSpace: "pre-wrap",
    verticalAlign: "baseline",
});

const CaptionName = styled("bdi")({
    display: "inline-block",
    maxWidth: "100%",
    verticalAlign: "baseline",
    "& > span": {
        display: "block",
        // Preserve the text baseline without creating a formatting context.
        overflow: "clip",
        textOverflow: "ellipsis",
        whiteSpace: "nowrap",
    },
});

const CaptionTime = styled("bdi")({
    display: "inline-block",
    color: "white",
    fontSize: "1.76rem",
    lineHeight: 39 / 32,
    whiteSpace: "nowrap",
    verticalAlign: "baseline",
    "&.now": {
        fontFamily: '"Gochi Hand", "Inter Variable", Inter, sans-serif',
        fontSize: "1.375rem",
        fontWeight: 400,
        lineHeight: "normal",
    },
});

const rollIn = keyframes`
    from { transform: translateY(var(--roll-from)); }
    to { transform: translateY(0); }
`;
const rollOut = keyframes`
    from { transform: translateY(0); }
    to { transform: translateY(var(--roll-to)); }
`;
const shrinkDigit = keyframes`
    from { width: var(--digit-width); }
    to { width: 0; }
`;

const DigitWindow = styled("span")({
    position: "relative",
    display: "inline-block",
    overflow: "hidden",
    verticalAlign: "bottom",
    "&.disappearing": {
        width: 0,
        animation: `${shrinkDigit} 320ms cubic-bezier(0.215, 0.61, 0.355, 1) both`,
    },
    "@media (prefers-reduced-motion: reduce)": { animation: "none" },
});

const DigitLayer = styled("span")({
    display: "inline-block",
    animation: `${rollIn} 320ms cubic-bezier(0.215, 0.61, 0.355, 1) both`,
    "&.outgoing": {
        position: "absolute",
        insetInlineStart: 0,
        top: 0,
        animation: `${rollOut} 320ms cubic-bezier(0.215, 0.61, 0.355, 1) both`,
    },
    "@media (prefers-reduced-motion: reduce)": {
        animation: "none",
        "&.outgoing": { display: "none" },
    },
});
