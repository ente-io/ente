import { SlideshowContext } from "pages/slideshow";
import { useContext, useEffect, useState } from "react";

export default function PhotoAuditorium({
    url,
    nextSlideUrl,
}: {
    url: string;
    nextSlideUrl: string;
}) {
    const { showNextSlide } = useContext(SlideshowContext);

    const [showPreloadedNextSlide, setShowPreloadedNextSlide] = useState(false);
    const [nextSlidePrerendered, setNextSlidePrerendered] = useState(false);
    const [prerenderTime, setPrerenderTime] = useState<number | null>(null);

    useEffect(() => {
        let timeout: NodeJS.Timeout;
        let timeout2: NodeJS.Timeout;

        if (nextSlidePrerendered) {
            const elapsedTime = prerenderTime ? Date.now() - prerenderTime : 0;
            const delayTime = Math.max(5000 - elapsedTime, 0);

            if (elapsedTime >= 5000) {
                setShowPreloadedNextSlide(true);
            } else {
                timeout = setTimeout(() => {
                    setShowPreloadedNextSlide(true);
                }, delayTime);
            }

            if (showNextSlide) {
                timeout2 = setTimeout(() => {
                    showNextSlide();
                    setNextSlidePrerendered(false);
                    setPrerenderTime(null);
                    setShowPreloadedNextSlide(false);
                }, delayTime);
            }
        }

        return () => {
            if (timeout) clearTimeout(timeout);
            if (timeout2) clearTimeout(timeout2);
        };
    }, [nextSlidePrerendered, showNextSlide, prerenderTime]);

    return (
        <div
            style={{
                width: "100vw",
                height: "100vh",
                backgroundImage: `url(${url})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
                backgroundBlendMode: "multiply",
                backgroundColor: "rgba(0, 0, 0, 0.5)",
            }}
        >
            <div
                style={{
                    height: "100%",
                    width: "100%",
                    display: "flex",
                    justifyContent: "center",
                    alignItems: "center",
                    backdropFilter: "blur(10px)",
                }}
            >
                <img
                    src={url}
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                        display: showPreloadedNextSlide ? "none" : "block",
                    }}
                />
                <img
                    src={nextSlideUrl}
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                        display: showPreloadedNextSlide ? "block" : "none",
                    }}
                    onLoad={() => {
                        setNextSlidePrerendered(true);
                        setPrerenderTime(Date.now());
                    }}
                />
            </div>
        </div>
    );
}
