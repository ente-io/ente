// TODO(PS): WIP gallery using upstream photoswipe
//
// Needs yarn workspace gallery add photoswipe@^5.4.4 (not committed yet).

if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
    console.warn("Using WIP upstream photoswipe");
} else {
    throw new Error("Whoa");
}

import { Button } from "@mui/material";

const FileViewer: React.FC = () => {
    return (
        <div>
            Hello<Button>Test</Button>
        </div>
    );
};

export default FileViewer;
