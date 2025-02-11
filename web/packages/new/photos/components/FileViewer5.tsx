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

import type { EnteFile } from "@/media/file.js";
import { Button, styled } from "@mui/material";
import { useEffect, useRef } from "react";
import PhotoSwipe from "./ps5/dist/photoswipe.esm.js";

interface FileViewerProps {
    /**
     * The list of files that are currently being displayed.
     *
     * Although the file viewer itself is called on to display a particular file
     * (specified by the {@link index} prop), the viewer is always used in the
     * context of a an album, or search results, or some other arbitrary list of
     * files. The {@link files} prop sets this underlying list of files.
     *
     * The user can also navigate through them from within the viewer by using
     * the arrow buttons.
     */
    files: EnteFile[];
    /**
     * The index from within {@link files} that should be, or is, currently
     * being displayed.
     *
     * It is set externally when the user activates a particular thumbnail in
     * the gallery. It is set internally (by the file viewer itself) when the
     * user scrolls through the files by using the arrow buttons.
     */
    index: number;
}

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
const FileViewer: React.FC<FileViewerProps> = ({
    open,
    onClose,
    files,
    index,
}) => {
    const pswpRef = useRef<PhotoSwipe | undefined>();

    useEffect(() => {
        const pswp = new PhotoSwipe({
            // Opaque background.
            bgOpacity: 1,
            // TODO(PS): padding option? for handling custom title bar.
            // TODO(PS): will we need this?
            mainClass: "our-extra-pswp-main-class",
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
        pswp.on("close", () => {
            console.log("pswp.on(close)")
            onClose();
        });
        pswpRef.current = pswp;

        return () => {
            if (pswpRef.current.isOpen) pswpRef.current.destroy();
            pswpRef.current = undefined;
        };
    }, []);

    console.log({ open, pswpIsOpen: pswpRef.current?.isOpen });

    useEffect(() => {
        const pswp = pswpRef.current!;
        if (open) {
            if (!pswp.isOpen) {
                // Initializing PhotoSwipe adds it to the DOM as a "dialog" div
                // with the class "pswp" (and others).
                pswp.init();
            }
        } else {
            if (pswp.isOpen) {
                // Closing PhotoSwipe removes it from the DOM.
                //
                // We get to this particular point if we're being closed
                // externally.
                pswp.close();
            }
        }
    }, [open]);

    const handleClose = () => {};

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
