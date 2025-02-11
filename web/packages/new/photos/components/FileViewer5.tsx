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
import { FileViewerPhotoSwipe } from "./FileViewerPhotoSwipe";

export interface FileViewerProps {
    /**
     * The list of files that are currently being displayed in the context in
     * which the file viewer was invoked.
     *
     * Although the file viewer is called on to display a particular file
     * (specified by the {@link initialIndex} prop), the viewer is always used
     * in the context of a an album, or search results, or some other arbitrary
     * list of files. The {@link files} prop sets this underlying list of files.
     *
     * After the initial file has been shown, the user can navigate through the
     * other files from within the viewer by using the arrow buttons.
     */
    files: EnteFile[];
    /**
     * The index of the file that should be initially shown.
     *
     * Subsequently the user may navigate between files by using the controls
     * provided within the file viewer itself.
     */
    initialIndex: number;
    /**
     * If true then the viewer does not show controls for downloading the file.
     */
    disableDownload?: boolean;
}

/**
 * A PhotoSwipe based image and video viewer.
 */
const FileViewer: React.FC<FileViewerProps> = ({
    open,
    onClose,
    files,
    initialIndex,
    disableDownload,
}) => {
    const pswpRef = useRef<FileViewerPhotoSwipe | undefined>();

    useEffect(() => {
        if (!open) {
            // The close state will be handled by the cleanup function.
            return;
        }

        const pswp = new FileViewerPhotoSwipe({
            files,
            initialIndex,
            onClose,
            disableDownload,
        });
        pswpRef.current = pswp;

        return () => {
            pswpRef.current?.closeIfNeeded();
            pswpRef.current = undefined;
        };
    }, [open]);

    return (
        <Container>
            <Button>Test</Button>
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
