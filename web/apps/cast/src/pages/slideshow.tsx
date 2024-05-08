import log from "@/next/log";
import { styled } from "@mui/material";
import { FilledCircleCheck } from "components/FilledCircleCheck";
import { SlideView } from "components/Slide";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { readCastData, renderableImageURLs } from "services/cast";

export default function Slideshow() {
    const [loading, setLoading] = useState(true);
    const [imageURL, setImageURL] = useState<string | undefined>();
    const [nextImageURL, setNextImageURL] = useState<string | undefined>();

    const router = useRouter();

    /** Go back to pairing page */
    const pair = () => router.push("/");

    useEffect(() => {
        let stop = false;

        const loop = async () => {
            try {
                const urlGenerator = renderableImageURLs(readCastData());
                while (!stop) {
                    const { value: urls, done } = await urlGenerator.next();
                    if (done) {
                        log.warn("Empty collection");
                        pair();
                        return;
                    }

                    setImageURL(urls[0]);
                    setNextImageURL(urls[1]);
                    setLoading(false);
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
    }, []);

    console.log("Rendering slideshow", { loading, imageURL, nextImageURL });

    if (loading) return <PairingComplete />;

    return <SlideView url={imageURL} nextURL={nextImageURL} />;
}

const PairingComplete: React.FC = () => {
    return (
        <PairingComplete_>
            <Items>
                <FilledCircleCheck />
                <h2>Pairing Complete</h2>
                <p>
                    We're preparing your album.
                    <br /> This should only take a few seconds.
                </p>
            </Items>
        </PairingComplete_>
    );
};

const PairingComplete_ = styled("div")`
    display: flex;
    min-height: 100svh;
    justify-content: center;
    align-items: center;

    line-height: 1.5rem;

    h2 {
        margin-block-end: 0;
    }
`;

const Items = styled("div")`
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
`;
