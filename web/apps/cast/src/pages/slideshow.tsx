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
    const [isEmpty, setIsEmpty] = useState(false);

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
                        // No items in this callection can be shown.
                        setIsEmpty(true);
                        // Go back to pairing screen after 3 seconds.
                        setTimeout(pair, 5000);
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
    if (isEmpty) return <NoItems />;

    return <SlideView url={imageURL} nextURL={nextImageURL} />;
}

const PairingComplete: React.FC = () => {
    return (
        <Message>
            <FilledCircleCheck />
            <h2>Pairing Complete</h2>
            <p>
                We're preparing your album.
                <br /> This should only take a few seconds.
            </p>
        </Message>
    );
};

const Message: React.FC<React.PropsWithChildren> = ({ children }) => {
    return (
        <Message_>
            <MessageItems>{children}</MessageItems>
        </Message_>
    );
};

const Message_ = styled("div")`
    display: flex;
    min-height: 100svh;
    justify-content: center;
    align-items: center;

    line-height: 1.5rem;

    h2 {
        margin-block-end: 0;
    }
`;

const MessageItems = styled("div")`
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
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
