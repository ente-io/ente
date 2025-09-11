import { Box, styled } from "@mui/material";
import { memo } from "react";
import Image from "next/image";
import type { JourneyPoint } from "./types";

interface PhotoFanProps {
    cluster: JourneyPoint[];
    onPhotoClick?: (cluster: JourneyPoint[], fileId: number) => void;
}

export const PhotoFan = memo<PhotoFanProps>(({
    cluster,
    onPhotoClick,
}) => {
    if (cluster.length === 0) {
        return null;
    }

    return (
        <PhotoFanContainer>
            {cluster.length === 2 && cluster[1] && (
                <PhotoFrameTwo
                    onClick={() =>
                        cluster[1] &&
                        onPhotoClick?.(cluster, cluster[1].fileId)
                    }
                >
                    <ImageWrapper sx={{ transform: 'skewY(-8deg) scale(1.1)' }}>
                        <Image
                            src={cluster[1].image}
                            alt={cluster[1].name}
                            fill
                            style={{ objectFit: "cover" }}
                            sizes="200px"
                        />
                    </ImageWrapper>
                </PhotoFrameTwo>
            )}
            {cluster.length >= 3 && (
                <>
                    {cluster[1] && (
                        <PhotoFrameLeft
                            onClick={() =>
                                cluster[1] &&
                                onPhotoClick?.(cluster, cluster[1].fileId)
                            }
                        >
                            <ImageWrapper sx={{ transform: 'skewY(8deg) scale(1.1)' }}>
                                <Image
                                    src={cluster[1].image}
                                    alt={cluster[1].name}
                                    fill
                                    style={{ objectFit: "cover" }}
                                    sizes="200px"
                                />
                            </ImageWrapper>
                        </PhotoFrameLeft>
                    )}
                    {cluster[2] && (
                        <PhotoFrameRight
                            onClick={() =>
                                cluster[2] &&
                                onPhotoClick?.(cluster, cluster[2].fileId)
                            }
                        >
                            <ImageWrapper sx={{ transform: 'skewY(-8deg) scale(1.1)' }}>
                                <Image
                                    src={cluster[2].image}
                                    alt={cluster[2].name}
                                    fill
                                    style={{ objectFit: "cover" }}
                                    sizes="200px"
                                />
                            </ImageWrapper>
                        </PhotoFrameRight>
                    )}
                </>
            )}

            {cluster[0] && (
                <MainPhotoFrame
                    onClick={() =>
                        cluster[0] &&
                        onPhotoClick?.(cluster, cluster[0].fileId)
                    }
                >
                    <Image
                        src={cluster[0].image}
                        alt={cluster[0].name}
                        fill
                        style={{ objectFit: "cover" }}
                        sizes="150px"
                    />

                    {cluster.length > 3 && (
                        <CountBadge>
                            +{cluster.length - 3}
                        </CountBadge>
                    )}
                </MainPhotoFrame>
            )}
        </PhotoFanContainer>
    );
});

// Styled components
const PhotoFanContainer = styled(Box)({
    position: "relative",
    width: "180px",
    height: "240px",
    transition: "transform 0.3s ease-in-out",
    cursor: "pointer",
    "&:hover": {
        transform: "scale(1.05)",
    },
});

const PhotoFrame = styled(Box)(({ theme }) => ({
    position: "absolute",
    border: "2px solid white",
    boxShadow: theme.shadows[10],
    zIndex: 10,
    width: "180px",
    height: "207px",
    borderRadius: "14px",
    overflow: "hidden",
    cursor: "pointer",
}));

const PhotoFrameTwo = styled(PhotoFrame)({
    transform: "translateX(33px) skewY(8deg)",
    top: "50%",
    left: "0",
    marginTop: "-103.5px",
});

const PhotoFrameLeft = styled(PhotoFrame)({
    transform: "translateX(-33px) skewY(-8deg)",
    top: "16.5px",
    left: "0",
});

const PhotoFrameRight = styled(PhotoFrame)({
    transform: "translateX(33px) skewY(8deg)",
    top: "16.5px",
    left: "0",
});

const MainPhotoFrame = styled(Box)(({ theme }) => ({
    position: "relative",
    width: "100%",
    height: "100%",
    border: "2px solid white",
    boxShadow: theme.shadows[10],
    zIndex: 20,
    borderRadius: "14px",
    overflow: "hidden",
    cursor: "pointer",
}));

const ImageWrapper = styled(Box)({
    position: "relative",
    width: "100%",
    height: "100%",
});

const CountBadge = styled(Box)({
    position: "absolute",
    bottom: "6px",
    right: "6px",
    background: "white",
    color: "black",
    borderRadius: "6px",
    padding: "4px 6px",
    minHeight: "20px",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "11px",
    fontWeight: "600",
    boxShadow: "0 1px 3px rgba(0,0,0,0.3)",
});