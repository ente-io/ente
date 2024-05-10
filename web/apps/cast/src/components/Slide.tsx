interface SlideViewProps {
    /** The URL of the image to show. */
    url: string;
    /** The URL of the next image that we will transition to. */
    nextURL: string;
}

/**
 * Show the image at {@link url} in a full screen view.
 *
 * Also show {@link nextURL} in an hidden image view to prepare the browser for
 * an imminent transition to it.
 */
export const SlideView: React.FC<SlideViewProps> = ({ url, nextURL }) => {
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
                    src={nextURL}
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                        display: "none",
                    }}
                />
                <img
                    src={url}
                    decoding="sync"
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                    }}
                />
            </div>
        </div>
    );
};
