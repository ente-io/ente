import { SlideshowContext } from 'pages/slideshow';
import { useContext, useEffect } from 'react';

export default function PhotoAuditorium({ url }: { url: string }) {
    const { showNextSlide } = useContext(SlideshowContext);

    useEffect(() => {
        const timeout = setTimeout(() => {
            showNextSlide();
        }, 5000);

        return () => {
            clearTimeout(timeout);
        };
    }, [url]);

    return (
        <div
            style={{
                width: '100vw',
                height: '100vh',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                backgroundImage: `url(${url})`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
                backgroundRepeat: 'no-repeat',
                backgroundBlendMode: 'multiply',
                backgroundColor: 'rgba(0, 0, 0, 0.5)',
            }}>
            <img
                src={url}
                style={{
                    maxWidth: '100%',
                    maxHeight: '100%',
                }}
            />
        </div>
    );
}
