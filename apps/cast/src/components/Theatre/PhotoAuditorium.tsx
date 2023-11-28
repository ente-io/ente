import { SlideshowContext } from 'pages/slideshow';
import { useContext, useEffect, useState } from 'react';

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

    useEffect(() => {
        let timeout;
        let prerenderTimeout;
        if (nextSlidePrerendered) {
            timeout = setTimeout(() => {
                setShowPreloadedNextSlide(true);

                if (showNextSlide) {
                    // wait 5s before showing next slide
                    prerenderTimeout = setTimeout(() => {
                        showNextSlide();
                    }, 5000);
                }
            }, 5000);
        }

        return () => {
            if (timeout) {
                clearTimeout(timeout);

                if (prerenderTimeout) {
                    clearTimeout(prerenderTimeout);
                }
            }
        };
    }, [nextSlidePrerendered, showNextSlide]);

    return (
        <div
            style={{
                width: '100vw',
                height: '100vh',
                backgroundImage: `url(${url})`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
                backgroundRepeat: 'no-repeat',
                backgroundBlendMode: 'multiply',
                backgroundColor: 'rgba(0, 0, 0, 0.5)',
            }}>
            <div
                style={{
                    height: '100%',
                    width: '100%',
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    backdropFilter: 'blur(10px)',
                }}>
                <img
                    src={url}
                    style={{
                        maxWidth: '100%',
                        maxHeight: '100%',
                        display: showPreloadedNextSlide ? 'none' : 'block',
                    }}
                />
                <img
                    src={nextSlideUrl}
                    style={{
                        maxWidth: '100%',
                        maxHeight: '100%',
                        display: showPreloadedNextSlide ? 'block' : 'none',
                    }}
                    onLoad={() => {
                        setNextSlidePrerendered(true);
                    }}
                />
            </div>
        </div>
    );
}
