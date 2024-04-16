import { useEffect } from "react";

interface PhotoAuditoriumProps {
    url: string;
    nextSlideUrl: string;
    showNextSlide: () => void;
}
export const PhotoAuditorium: React.FC<PhotoAuditoriumProps> = ({
    url,
    nextSlideUrl,
    showNextSlide,
}) => {
    useEffect(() => {
        const timeoutId = window.setTimeout(() => {
            showNextSlide();
        }, 10000);

        return () => {
            if (timeoutId) clearTimeout(timeoutId);
        };
    }, [showNextSlide]);

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
                    src={nextSlideUrl}
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                        display: "none",
                    }}
                />
                <img
                    src={url}
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                    }}
                />
            </div>
        </div>
    );
};
