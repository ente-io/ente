import PhotoOutlinedIcon from "@mui/icons-material/PhotoOutlined";
import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { styled } from "@mui/material";
import { Overlay } from "ente-base/components/containers";
import { FileType } from "ente-media/file-type";
import React from "react";

/**
 * A thumbnail shown when we're loading the thumbnail for a file.
 * @returns
 */
export const LoadingThumbnail = () => (
    <Overlay sx={{ backgroundColor: "fill.faint", borderRadius: "4px" }} />
);

interface StaticThumbnailProps {
    /**
     * The type of the file for which we're showing the placeholder thumbnail.
     *
     * Expected to be one of {@link FileType}.
     */
    fileType: number;
}

/**
 * A thumbnail shown when a file does not have a thumbnail.
 */
export const StaticThumbnail: React.FC<StaticThumbnailProps> = ({
    fileType,
}) => (
    <CenteredOverlay
        sx={{
            backgroundColor: "fill.faint",
            borderWidth: "1px",
            borderStyle: "solid",
            borderColor: "stroke.faint",
            borderRadius: "4px",
            "& > svg": { color: "stroke.muted", fontSize: "50px" },
        }}
    >
        {fileType != FileType.video ? (
            <PhotoOutlinedIcon />
        ) : (
            <PlayCircleOutlineOutlinedIcon />
        )}
    </CenteredOverlay>
);

const CenteredOverlay = styled(Overlay)`
    display: flex;
    justify-content: center;
    align-items: center;
`;
