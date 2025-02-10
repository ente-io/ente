/* eslint-disable */
// @ts-nocheck

// TODO(PS): WIP gallery using upstream photoswipe
//
// Needs (not committed yet):
// yarn workspace gallery add photoswipe@^5.4.4
// mv node_modules/photoswipe packages/new/photos/components/ps5

if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
    console.warn("Using WIP upstream photoswipe");
} else {
    throw new Error("Whoa");
}

import { Button, styled } from "@mui/material";
import { useEffect } from "react";
import PhotoSwipeLightBox from "./ps5/dist/photoswipe-lightbox.esm.js";
import PhotoSwipe from "./ps5/dist/photoswipe.esm.js";

const FileViewer: React.FC = () => {
    const pswpRef = useRef<PhotoSwipe | undefined>();
    console.log(PhotoSwipeLightBox);
    useEffect(() => {
        const pswp = new PhotoSwipe({
            // mainClass: "our-extra-pswp-main-class",
        });
        pswp.init();
        pswpRef.current = pswp;

        return () => {
            pswp.destroy();
            pswpRef.current = undefined;
        };
    }, []);
    return (
        <Container>
            <Button>Test</Button>
            <div id="test-gallery">
                <a
                    href="https://cdn.photoswipe.com/photoswipe-demo-images/photos/2/img-2500.jpg"
                    data-pswp-width="1669"
                    data-pswp-height="2500"
                    target="_blank"
                >
                    <img
                        src="https://cdn.photoswipe.com/photoswipe-demo-images/photos/2/img-200.jpg"
                        alt=""
                    />
                </a>
            </div>
        </Container>
    );
};

const Container = styled("div")`
    border: 1px solid red;

    #test-gallery {
        border: 1px solid red;
        min-height: 10px;
    }
`;

export default FileViewer;
