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

import { Button } from "@mui/material";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import PhotoSwipeLightBox from "./ps5/dist/photoswipe-lightbox.esm.js";

const FileViewer: React.FC = () => {
    console.log(PhotoSwipeLightBox);
    return (
        <div>
            Hello<Button>Test</Button>
        </div>
    );
};

export default FileViewer;
