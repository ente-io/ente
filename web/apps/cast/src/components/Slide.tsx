import { styled } from "@mui/material";

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
export const SlideView: React.FC<SlideViewProps> = ({ url }) => {
    return (
        <Container
            style={{
                backgroundImage: `url(${url})`,
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
                    decoding="sync"
                    style={{
                        maxWidth: "100%",
                        maxHeight: "100%",
                    }}
                />
            </div>
        </Container>
    );
};

const Container = styled("div")`
    width: 100%;
    height: 100%;
    /* backgroundImage: url({url}), */
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    background-blend-mode: multiply;
    background-color: rgba(0, 0, 0, 0.5);
    /* Smooth out the transition a bit.
     *
     * For the img itself, we set decoding="sync" to have it switch seamlessly.
     * But there does not seem to be a way of setting decoding sync for the
     * background image, and for large (multi-MB) images the background image
     * switch is still visually non-atomic.
     *
     * As a workaround, add a long transition so that the background image
     * transitions in a more "fade-across" manner. This effect might or might
     * not be visually the best though.
     *
     * Does not work in Firefox, but that's fine, this is only a slight tweak,
     * not a functional requirement.
     */
    transition: all 2s;
`;
