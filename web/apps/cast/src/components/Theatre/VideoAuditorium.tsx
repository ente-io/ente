import mime from "mime-types";
import { SlideshowContext } from "pages/slideshow";
import { useContext, useEffect, useRef } from "react";

export default function VideoAuditorium({
    name,
    url,
}: {
    name: string;
    url: string;
}) {
    const { showNextSlide } = useContext(SlideshowContext);

    const videoRef = useRef<HTMLVideoElement>(null);

    useEffect(() => {
        attemptPlay();
    }, [url, videoRef]);

    const attemptPlay = async () => {
        if (videoRef.current) {
            try {
                await videoRef.current.play();
            } catch {
                showNextSlide();
            }
        }
    };

    return (
        <div
            style={{
                width: "100vw",
                height: "100vh",
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
            }}
        >
            <video
                ref={videoRef}
                autoPlay
                controls
                style={{
                    maxWidth: "100vw",
                    maxHeight: "100vh",
                }}
                onError={showNextSlide}
                onEnded={showNextSlide}
            >
                <source src={url} type={mime.lookup(name)} />
            </video>
        </div>
    );
}
