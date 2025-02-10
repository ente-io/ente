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
import { useEffect, useRef } from "react";
import PhotoSwipeLightBox from "./ps5/dist/photoswipe-lightbox.esm.js";
import PhotoSwipe from "./ps5/dist/photoswipe.esm.js";

/**
 * The {@link FileViewer} is our PhotoSwipe based image and video viewer.
 *
 * ---
 *
 * [Note: PhotoSwipe]
 *
 * PhotoSwipe is a library that behaves similarly to the OG "lightbox" image
 * gallery JavaScript component from the middle ages.
 *
 * We don't need the lightbox functionality since we already have our own
 * thumbnail list (the "gallery"), so we only use the "Core" PhotoSwipe module
 * as our image viewer component.
 *
 * When the user clicks on one of the thumbnails in our gallery, we make the
 * root PhotoSwipe component visible. Within the DOM this is a dialog that takes
 * up the entire viewport, and shows the image etc, and various controls.
 *
 * The documentation for PhotoSwipe is at https://photoswipe.com/.
 */
const FileViewer: React.FC = () => {
    const pswpRef = useRef<PhotoSwipe | undefined>();
    console.log(PhotoSwipeLightBox);
    useEffect(() => {
        const pswp = new PhotoSwipe({
            // mainClass: "our-extra-pswp-main-class",
        });
        // Provide data about slides to PhotoSwipe via callbacks
        // https://photoswipe.com/data-sources/#dynamically-generated-data
        pswp.addFilter("numItems", () => {
            return 2;
        });
        pswp.addFilter("itemData", (itemData, index) => {
            console.log({ itemData, index });
            return {
                src: `https://dummyimage.com/100/777/fff/?text=i${index}`,
                width: 100,
                height: 100,
            };
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
