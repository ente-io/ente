import { memo } from "react";
import type { JourneyPoint } from "./types";
import { PhotoFan } from "./PhotoFan";

interface TimelineLocationProps {
    cluster: JourneyPoint[];
    index: number;
    photoClusters: JourneyPoint[][];
    scrollProgress: number;
    journeyData: JourneyPoint[];
    onRef: (el: HTMLDivElement | null) => void;
    onPhotoClick?: (cluster: JourneyPoint[], fileId: number) => void;
}

// Component for timeline location item
export const TimelineLocation = memo<TimelineLocationProps>(({
    cluster,
    index,
    photoClusters,
    scrollProgress,
    journeyData,
    onRef,
    onPhotoClick,
}) => {
    const isLeft = index % 2 === 0;
    const firstPhoto = cluster[0];
    if (!firstPhoto) return null;
    const sortedData = [...journeyData].sort(
        (a, b) =>
            new Date(a.timestamp).getTime() -
            new Date(b.timestamp).getTime(),
    );
    const firstData = sortedData[0];
    if (!firstData) return null;
    const firstDate = new Date(firstData.timestamp);
    const photoDate = new Date(firstPhoto.timestamp);

    const firstDateOnly = new Date(
        firstDate.getFullYear(),
        firstDate.getMonth(),
        firstDate.getDate(),
    );
    const photoDateOnly = new Date(
        photoDate.getFullYear(),
        photoDate.getMonth(),
        photoDate.getDate(),
    );
    const diffTime = photoDateOnly.getTime() - firstDateOnly.getTime();
    const dayNumber = Math.floor(diffTime / (1000 * 60 * 60 * 24)) + 1;

    const isReached =
        scrollProgress >= index / Math.max(1, photoClusters.length - 1);

    return (
        <div
            ref={onRef}
            id={`location-${index}`}
            className="timeline-location"
            style={{
                position: "relative",
                display: "flex",
                alignItems: "center",
                marginBottom:
                    index === photoClusters.length - 1 ? "24px" : "192px",
            }}
        >
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    top: "50%",
                    transform: "translate(-50%, -50%)",
                    width: "24px",
                    height: "40px",
                    borderRadius: "50%",
                    zIndex: 10,
                    backgroundColor: "white",
                }}
            ></div>
            <div
                className="timeline-dot"
                style={{
                    position: "absolute",
                    left: "50%",
                    top: "50%",
                    transform: "translate(-50%, -50%)",
                    borderRadius: "50%",
                    border: "2px solid white",
                    zIndex: 20,
                    width: "12px",
                    height: "12px",
                    transition: "all 0.3s",
                    backgroundColor: isReached ? "#10b981" : "#111827",
                    boxShadow: isReached
                        ? "0 0 0 3px rgba(34, 197, 94, 0.3), 0 0 0 6px rgba(34, 197, 94, 0.15)"
                        : "none",
                }}
            ></div>

            {isLeft ? (
                <>
                    <div
                        style={{
                            width: "50%",
                            paddingRight: "32px",
                            paddingTop: "58px",
                            textAlign: "right",
                        }}
                    >
                        <div
                            style={{
                                display: "inline-flex",
                                alignItems: "center",
                                border: "1px solid #e5e7eb",
                                borderRadius: "8px",
                                padding: "4px 12px",
                                marginBottom: "10px",
                            }}
                        >
                            <span
                                style={{
                                    fontSize: "11px",
                                    fontWeight: "600",
                                    color: "#4b5563",
                                    textTransform: "uppercase",
                                    letterSpacing: "0.15em",
                                }}
                            >
                                DAY {dayNumber} •{" "}
                                {new Date(firstPhoto.timestamp)
                                    .toLocaleDateString("en-US", {
                                        month: "long",
                                        day: "numeric",
                                    })
                                    .toUpperCase()}
                            </span>
                        </div>
                        <h3
                            style={{
                                fontSize: "20px",
                                fontWeight: "600",
                                color: "#111827",
                                textAlign: "right",
                                margin: "0",
                                lineHeight: "1.2",
                            }}
                        >
                            {firstPhoto.name}
                        </h3>
                        <p
                            style={{
                                fontSize: "14px",
                                color: "#6b7280",
                                textAlign: "right",
                                margin: "4px 0 0 0",
                            }}
                        >
                            {firstPhoto.country}
                        </p>
                    </div>
                    <div
                        style={{
                            width: "50%",
                            paddingLeft:
                                cluster.length >= 3 ? "72px" : "40px",
                        }}
                    >
                        <PhotoFan
                            cluster={cluster}
                            onPhotoClick={onPhotoClick}
                        />
                    </div>
                </>
            ) : (
                <>
                    <div
                        style={{
                            width: "50%",
                            display: "flex",
                            justifyContent: "flex-end",
                            paddingRight:
                                cluster.length >= 3 ? "72px" : "40px",
                        }}
                    >
                        <PhotoFan
                            cluster={cluster}
                            onPhotoClick={onPhotoClick}
                        />
                    </div>
                    <div
                        style={{
                            width: "50%",
                            paddingLeft: "32px",
                            paddingTop: "58px",
                            textAlign: "left",
                        }}
                    >
                        <div
                            style={{
                                display: "inline-flex",
                                alignItems: "center",
                                border: "1px solid #e5e7eb",
                                borderRadius: "8px",
                                padding: "4px 12px",
                                marginBottom: "10px",
                            }}
                        >
                            <span
                                style={{
                                    fontSize: "11px",
                                    fontWeight: "600",
                                    color: "#4b5563",
                                    textTransform: "uppercase",
                                    letterSpacing: "0.15em",
                                }}
                            >
                                DAY {dayNumber} •{" "}
                                {new Date(firstPhoto.timestamp)
                                    .toLocaleDateString("en-US", {
                                        month: "long",
                                        day: "numeric",
                                    })
                                    .toUpperCase()}
                            </span>
                        </div>
                        <h3
                            style={{
                                fontSize: "20px",
                                fontWeight: "600",
                                color: "#111827",
                                textAlign: "left",
                                margin: "0",
                                lineHeight: "1.2",
                            }}
                        >
                            {firstPhoto.name}
                        </h3>
                        <p
                            style={{
                                fontSize: "14px",
                                color: "#6b7280",
                                textAlign: "left",
                                margin: "4px 0 0 0",
                            }}
                        >
                            {firstPhoto.country}
                        </p>
                    </div>
                </>
            )}
        </div>
    );
});