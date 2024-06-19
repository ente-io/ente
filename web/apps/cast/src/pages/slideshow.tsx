import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { styled } from "@mui/material";
import { FilledCircleCheck } from "components/FilledCircleCheck";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { readCastData } from "services/cast-data";
import { isChromecast } from "services/chromecast";
import { imageURLGenerator } from "services/render";

export default function Slideshow() {
    const [isEmpty, setIsEmpty] = useState(false);
    const [imageURL, setImageURL] = useState<string | undefined>();

    const router = useRouter();

    useEffect(() => {
        /** Go back to pairing page */
        const pair = () => void router.push("/");

        let stop = false;

        const loop = async () => {
            try {
                const urlGenerator = imageURLGenerator(ensure(readCastData()));
                while (!stop) {
                    const { value: url, done } = await urlGenerator.next();
                    if (done == true || !url) {
                        // No items in this callection can be shown.
                        setIsEmpty(true);
                        // Go back to pairing screen after 5 seconds.
                        setTimeout(pair, 5000);
                        return;
                    }

                    setImageURL(url);
                }
            } catch (e) {
                log.error("Failed to prepare generator", e);
                pair();
            }
        };

        void loop();

        return () => {
            stop = true;
        };
    }, [router]);

    if (isEmpty) return <NoItems />;
    if (!imageURL) return <PairingComplete />;

    return isChromecast() ? (
        <SlideViewChromecast url={imageURL} />
    ) : (
        <SlideView url={imageURL} />
    );
}

const PairingComplete: React.FC = () => {
    return (
        <Message>
            <FilledCircleCheck />
            <h2>Pairing Complete</h2>
            <p>
                {"We're preparing your album"}.
                <br /> This should only take a few seconds.
            </p>
        </Message>
    );
};

const Message = styled("div")`
    display: flex;
    flex-direction: column;
    height: 100%;
    justify-content: center;
    align-items: center;
    text-align: center;

    line-height: 1.5rem;

    h2 {
        margin-block-end: 0;
    }
`;

const NoItems: React.FC = () => {
    return (
        <Message>
            <h2>Try another album</h2>
            <p>
                This album has no photos that can be shown here
                <br /> Please try another album
            </p>
        </Message>
    );
};

interface SlideViewProps {
    /** The URL of the image to show. */
    url: string;
}

const SlideView: React.FC<SlideViewProps> = ({ url }) => {
    return (
        <SlideView_ style={{ backgroundImage: `url(${url})` }}>
            <img src={url} decoding="sync" alt="" />
        </SlideView_>
    );
};

const SlideView_ = styled("div")`
    width: 100%;
    height: 100%;

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
     * transitions in a more "fade-to" manner. This effect might or might not be
     * visually the best though.
     *
     * Does not work in Firefox, but that's fine, this is only a slight tweak,
     * not a functional requirement.
     */
    transition: all 2s;

    img {
        width: 100%;
        height: 100%;
        backdrop-filter: blur(10px);
        object-fit: contain;
    }
`;

/**
 * Variant of {@link SlideView} for use when we're running on Chromecast.
 *
 * Chromecast devices have trouble with
 *
 *     backdrop-filter: blur(10px);
 *
 * So emulate a cheaper approximation for use on Chromecast.
 */
const SlideViewChromecast: React.FC<SlideViewProps> = ({ url }) => {
    return (
        <SlideViewChromecast_>
            <img className="svc-bg" src={url} alt="" />
            <img className="svc-content" src={url} decoding="sync" alt="" />
        </SlideViewChromecast_>
    );
};

const SlideViewChromecast_ = styled("div")`
    width: 100%;
    height: 100%;

    /* We can't set opacity of background-image, so use a wrapper */
    position: relative;
    overflow: hidden;

    img.svc-bg {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;
        opacity: 0.1;
    }

    img.svc-content {
        position: relative;
        width: 100%;
        height: 100%;
        object-fit: contain;
    }
`;
