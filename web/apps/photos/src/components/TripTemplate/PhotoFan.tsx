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
        <div
            className="photo-fan-hover"
            style={{
                position: "relative",
                width: "180px",
                height: "240px",
            }}
        >
            {cluster.length === 2 && cluster[1] && (
                <div
                    onClick={() =>
                        cluster[1] &&
                        onPhotoClick?.(cluster, cluster[1].fileId)
                    }
                    style={{
                        position: "absolute",
                        border: "2px solid white",
                        boxShadow:
                            "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
                        zIndex: 10,
                        width: "180px",
                        height: "207px",
                        borderRadius: "14px",
                        overflow: "hidden",
                        transform: "translateX(33px) skewY(8deg)",
                        top: "50%",
                        left: "0",
                        marginTop: "-103.5px",
                        cursor: "pointer",
                    }}
                >
                    <div
                        style={{
                            position: "relative",
                            width: "100%",
                            height: "100%",
                            transform: "skewY(-8deg) scale(1.1)",
                        }}
                    >
                        <Image
                            src={cluster[1].image}
                            alt={cluster[1].name}
                            fill
                            style={{ objectFit: "cover" }}
                            sizes="200px"
                        />
                    </div>
                </div>
            )}
            {cluster.length >= 3 && (
                <>
                    {cluster[1] && (
                        <div
                            onClick={() =>
                                cluster[1] &&
                                onPhotoClick?.(cluster, cluster[1].fileId)
                            }
                            style={{
                                position: "absolute",
                                border: "2px solid white",
                                boxShadow:
                                    "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
                                zIndex: 10,
                                width: "180px",
                                height: "207px",
                                borderRadius: "14px",
                                overflow: "hidden",
                                transform: "translateX(-33px) skewY(-8deg)",
                                top: "16.5px",
                                left: "0",
                                cursor: "pointer",
                            }}
                        >
                            <div
                                style={{
                                    position: "relative",
                                    width: "100%",
                                    height: "100%",
                                    transform: "skewY(8deg) scale(1.1)",
                                }}
                            >
                                <Image
                                    src={cluster[1].image}
                                    alt={cluster[1].name}
                                    fill
                                    style={{ objectFit: "cover" }}
                                    sizes="200px"
                                />
                            </div>
                        </div>
                    )}
                    {cluster[2] && (
                        <div
                            onClick={() =>
                                cluster[2] &&
                                onPhotoClick?.(cluster, cluster[2].fileId)
                            }
                            style={{
                                position: "absolute",
                                border: "2px solid white",
                                boxShadow:
                                    "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
                                zIndex: 10,
                                width: "180px",
                                height: "207px",
                                borderRadius: "14px",
                                overflow: "hidden",
                                transform: "translateX(33px) skewY(8deg)",
                                top: "16.5px",
                                left: "0",
                                cursor: "pointer",
                            }}
                        >
                            <div
                                style={{
                                    position: "relative",
                                    width: "100%",
                                    height: "100%",
                                    transform: "skewY(-8deg) scale(1.1)",
                                }}
                            >
                                <Image
                                    src={cluster[2].image}
                                    alt={cluster[2].name}
                                    fill
                                    style={{ objectFit: "cover" }}
                                    sizes="200px"
                                />
                            </div>
                        </div>
                    )}
                </>
            )}

            {cluster[0] && (
                <div
                    onClick={() =>
                        cluster[0] &&
                        onPhotoClick?.(cluster, cluster[0].fileId)
                    }
                    style={{
                        position: "relative",
                        width: "100%",
                        height: "100%",
                        border: "2px solid white",
                        boxShadow:
                            "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
                        zIndex: 20,
                        borderRadius: "14px",
                        overflow: "hidden",
                        cursor: "pointer",
                    }}
                >
                    <Image
                        src={cluster[0].image}
                        alt={cluster[0].name}
                        fill
                        style={{ objectFit: "cover" }}
                        sizes="150px"
                    />

                    {cluster.length > 3 && (
                        <div
                            style={{
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
                            }}
                        >
                            +{cluster.length - 3}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
});