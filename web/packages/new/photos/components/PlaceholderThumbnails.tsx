import { Overlay } from "@/base/components/containers";
import { FileType } from "@/media/file-type";
import PhotoOutlinedIcon from "@mui/icons-material/PhotoOutlined";
import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { styled } from "@mui/material";
import React from "react";

interface Iprops {
    fileType: FileType;
}

const CenteredOverlay = styled(Overlay)`
    display: flex;
    justify-content: center;
    align-items: center;
`;

export const StaticThumbnail: React.FC<Iprops> = (props) => {
    return (
        <CenteredOverlay
            sx={(theme) => ({
                backgroundColor: theme.colors.fill.faint,
                borderWidth: "1px",
                borderStyle: "solid",
                borderColor: theme.colors.stroke.faint,
                borderRadius: "4px",
                "& > svg": {
                    color: theme.colors.stroke.muted,
                    fontSize: "50px",
                },
            })}
        >
            {props.fileType !== FileType.video ? (
                <PhotoOutlinedIcon />
            ) : (
                <PlayCircleOutlineOutlinedIcon />
            )}
        </CenteredOverlay>
    );
};

export const LoadingThumbnail = () => {
    return (
        <Overlay
            sx={(theme) => ({
                backgroundColor: theme.colors.fill.faint,
                borderRadius: "4px",
            })}
        />
    );
};
