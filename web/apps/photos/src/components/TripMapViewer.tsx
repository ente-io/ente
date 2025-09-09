import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { downloadManager } from "ente-gallery/services/download";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import dynamic from "next/dynamic";
import Image from "next/image";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useMap } from "react-leaflet";

// Dynamically import react-leaflet components to prevent SSR issues
const MapContainer = dynamic(
    () => import("react-leaflet").then((mod) => mod.MapContainer),
    { ssr: false },
);
const TileLayer = dynamic(
    () => import("react-leaflet").then((mod) => mod.TileLayer),
    { ssr: false },
);
const Marker = dynamic(
    () => import("react-leaflet").then((mod) => mod.Marker),
    { ssr: false },
);

interface JourneyPoint {
    lat: number;
    lng: number;
    name: string;
    country: string;
    timestamp: string;
    image: string;
    fileId: number;
}

// Reverse geocoding function using Stadia Maps
// Works without API key for localhost development
const getLocationName = async (
    lat: number,
    lng: number,
    photoIndex?: number,
): Promise<{ place: string; country: string }> => {
    try {
        const response = await fetch(
            `https://api.stadiamaps.com/geocoding/v1/reverse?point.lat=${lat}&point.lon=${lng}`,
        );

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Extract location name from the response
        const feature = data.features?.[0];
        if (feature?.properties) {
            const props = feature.properties;

            // Build location name with city and state/region for better context
            const city = props.locality || props.neighbourhood;

            // Get location name
            const locationName =
                city || props.county || props.region || props.name || "Unknown";

            // Get country info
            const country = props.country || "Unknown";

            return { place: locationName, country: country };
        }

        // Fallback if no location found
        return {
            place: photoIndex
                ? `Location ${photoIndex}`
                : `Location ${lat.toFixed(2)}, ${lng.toFixed(2)}`,
            country: "Unknown",
        };
    } catch (error) {
        console.error("Stadia Maps geocoding error:", error);
        // Fallback on error
        return {
            place: photoIndex ? `Location ${photoIndex}` : `Unknown Location`,
            country: "Unknown",
        };
    }
};

// Component to handle map events inside MapContainer
const MapEvents = ({
    setMapRef,
    setCurrentZoom,
    setTargetZoom,
}: {
    setMapRef: (map: any) => void;
    setCurrentZoom: (zoom: number) => void;
    setTargetZoom: (zoom: number | null) => void;
}) => {
    const map = useMap();

    useEffect(() => {
        if (typeof window !== "undefined" && map) {
            setMapRef(map);

            map.on("zoomend", () => {
                setCurrentZoom(map.getZoom());
                setTargetZoom(null);
            });

            return () => {
                map.off("zoomend");
            };
        }
    }, [map, setMapRef, setCurrentZoom, setTargetZoom]);

    return null;
};

// Component for the trip cover section only
const TripCover = ({
    journeyData,
    photoClusters,
    albumTitle,
    ownerName,
}: {
    journeyData: JourneyPoint[];
    photoClusters: JourneyPoint[][];
    albumTitle?: string;
    ownerName?: string;
}) => {
    const sortedData = [...journeyData].sort(
        (a, b) =>
            new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );
    const firstDate = new Date(sortedData[0].timestamp);
    const lastDate = new Date(sortedData[sortedData.length - 1].timestamp);
    const diffTime = Math.abs(lastDate.getTime() - firstDate.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    const monthYear = firstDate.toLocaleDateString("en-US", {
        month: "long",
        year: "numeric",
    });

    return (
        <div style={{ marginBottom: "96px" }}>
            <div
                style={{
                    aspectRatio: "16/8",
                    position: "relative",
                    marginBottom: "12px",
                    borderRadius: "24px",
                    overflow: "hidden",
                }}
            >
                <Image
                    src={journeyData[0].image}
                    alt="Trip Cover"
                    fill
                    style={{ objectFit: "cover" }}
                    sizes="300px"
                />
                <div
                    style={{
                        position: "absolute",
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: "128px",
                        background:
                            "linear-gradient(to top, black, transparent)",
                    }}
                ></div>
                <div
                    style={{
                        position: "absolute",
                        bottom: 0,
                        left: 0,
                        right: 0,
                        padding: "24px",
                        color: "white",
                    }}
                >
                    <h1
                        style={{
                            fontSize: "30px",
                            fontWeight: "bold",
                            marginBottom: "2px",
                        }}
                    >
                        {albumTitle || "Trip Journey"}
                    </h1>
                    <p
                        style={{
                            color: "rgba(255, 255, 255, 0.8)",
                            fontSize: "16px",
                            fontWeight: "600",
                            margin: "0",
                        }}
                    >
                        {monthYear} • {diffDays} days • {photoClusters.length}{" "}
                        locations
                    </p>
                </div>
            </div>
        </div>
    );
};

// Component for the trip started section
const TripStartedSection = ({
    journeyData,
}: {
    journeyData: JourneyPoint[];
}) => {
    const sortedData = [...journeyData].sort(
        (a, b) =>
            new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );
    const firstDate = new Date(sortedData[0].timestamp);

    return (
        <div
            style={{
                position: "relative",
                marginTop: "64px",
                marginBottom: "200px",
                textAlign: "center",
                zIndex: 1,
            }}
        >
            <div
                style={{
                    fontSize: "20px",
                    fontWeight: "600",
                    color: "#111827",
                    marginBottom: "2px",
                    lineHeight: "1.2",
                    backgroundColor: "white",
                    padding: "4px 8px",
                    borderRadius: "4px",
                    display: "inline-block",
                }}
            >
                Trip started
            </div>
            <br />
            <div
                style={{
                    fontSize: "14px",
                    color: "#6b7280",
                    backgroundColor: "white",
                    padding: "2px 6px",
                    borderRadius: "4px",
                    display: "inline-block",
                    marginTop: "0px",
                }}
            >
                {firstDate.toLocaleDateString("en-US", {
                    month: "long",
                    day: "2-digit",
                })}
            </div>

            {/* Starting dot after some space */}
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    top: "80px",
                    transform: "translate(-50%, 0)",
                    borderRadius: "50%",
                    border: "2px solid white",
                    zIndex: 20,
                    width: "12px",
                    height: "12px",
                    backgroundColor: "#d1d5db",
                }}
            ></div>
        </div>
    );
};

// Component for the timeline progress line
const TimelineProgressLine = ({
    locationPositions,
    scrollProgress,
    hasUserScrolled,
    photoClusters,
}: {
    locationPositions: { top: number; center: number }[];
    scrollProgress: number;
    hasUserScrolled: boolean;
    photoClusters: JourneyPoint[][];
}) => {
    if (photoClusters.length === 0 || locationPositions.length === 0) {
        return null;
    }

    const firstLocationCenter = locationPositions[0].center;
    const lastLocationCenter =
        locationPositions[locationPositions.length - 1].center;

    if (scrollProgress <= 0 || !hasUserScrolled) {
        return null;
    }

    return (
        <div
            style={{
                position: "absolute",
                left: "50%",
                transform: "translateX(-1.5px)",
                width: "3px",
                backgroundColor: "#10b981",
                top: `${firstLocationCenter}px`,
                height: `${
                    (lastLocationCenter - firstLocationCenter) * scrollProgress
                }px`,
            }}
        />
    );
};

// Component for timeline base line
const TimelineBaseLine = ({
    locationPositions,
}: {
    locationPositions: { top: number; center: number }[];
}) => {
    const timelineContainer = document.querySelector("#timeline-container");
    if (!timelineContainer || locationPositions.length === 0) {
        return null;
    }

    const locationElements =
        timelineContainer.querySelectorAll(".timeline-location");
    if (locationElements.length === 0) {
        return null;
    }

    const lastLocation = locationElements[
        locationElements.length - 1
    ] as HTMLElement;
    const lastLocationRect = lastLocation.getBoundingClientRect();
    const heightToLastDot =
        lastLocation.offsetTop + lastLocationRect.height / 2;

    const firstLocationCenter = locationPositions[0]?.center || 0;

    return (
        <>
            {/* Long dashed line from trip started dot to first location */}
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    transform: "translateX(-1.5px)",
                    width: "3px",
                    backgroundImage:
                        "linear-gradient(to bottom, #d1d5db 55%, transparent 55%)",
                    backgroundSize: "100% 22px",
                    backgroundRepeat: "repeat-y",
                    top: "-158px",
                    height: `${firstLocationCenter + 158}px`,
                    zIndex: 0,
                }}
            />
            {/* Solid line from first location to end */}
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    transform: "translateX(-1.5px)",
                    width: "3px",
                    backgroundColor: "#d1d5db",
                    top: `${firstLocationCenter}px`,
                    height: `${heightToLastDot - firstLocationCenter}px`,
                }}
            />
        </>
    );
};

// Component for photo fan display
const PhotoFan = ({
    cluster,
    onPhotoClick,
}: {
    cluster: JourneyPoint[];
    onPhotoClick?: (cluster: JourneyPoint[], fileId: number) => void;
}) => {
    if (!cluster || cluster.length === 0) return null;

    return (
        <div style={{ position: "relative", width: "180px", height: "240px" }}>
            {cluster.length === 2 && cluster[1] && (
                <div
                    onClick={() =>
                        cluster[1] && onPhotoClick?.(cluster, cluster[1].fileId)
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
                        cluster[0] && onPhotoClick?.(cluster, cluster[0].fileId)
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
};

// Component for timeline location item
const TimelineLocation = ({
    cluster,
    index,
    photoClusters,
    scrollProgress,
    journeyData,
    onRef,
    onPhotoClick,
}: {
    cluster: JourneyPoint[];
    index: number;
    photoClusters: JourneyPoint[][];
    scrollProgress: number;
    journeyData: JourneyPoint[];
    onRef: (el: HTMLDivElement | null) => void;
    onPhotoClick?: (cluster: JourneyPoint[], fileId: number) => void;
}) => {
    const isLeft = index % 2 === 0;
    const firstPhoto = cluster[0];
    if (!firstPhoto) return null;
    const sortedData = [...journeyData].sort(
        (a, b) =>
            new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );
    const firstDate = new Date(sortedData[0].timestamp);
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
                                        month: "short",
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
                            paddingLeft: cluster.length >= 3 ? "72px" : "40px",
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
                            paddingRight: cluster.length >= 3 ? "72px" : "40px",
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
                                        month: "short",
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
};

interface TripMapViewerProps {
    files: EnteFile[];
    collection?: Collection;
    albumTitle?: string;
    ownerName?: string;
    user?: any; // User object for FileViewer
    // FileViewer related props (optional, can be added as needed)
    enableDownload?: boolean;
    onSetOpenFileViewer?: (open: boolean) => void;
    onRemotePull?: () => Promise<void>;
}

export const TripMapViewer: React.FC<TripMapViewerProps> = ({
    files,
    collection,
    albumTitle,
    ownerName,
    user,
    enableDownload,
    onSetOpenFileViewer,
    onRemotePull,
}) => {
    // Extract collection info if available
    const collectionTitle = collection?.name || albumTitle || "Trip Journey";
    const collectionOwner = collection?.owner?.email || ownerName;
    // Add CSS animation for spinner
    useEffect(() => {
        if (typeof document !== "undefined") {
            const style = document.createElement("style");
            style.textContent = `
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `;
            document.head.appendChild(style);
            return () => {
                document.head.removeChild(style);
            };
        }
    }, []);

    const [journeyData, setJourneyData] = useState<JourneyPoint[]>([]);
    const [isClient, setIsClient] = useState(false);
    const [isLoadingPhotos, setIsLoadingPhotos] = useState(true);
    const [isLoadingLocations, setIsLoadingLocations] = useState(false);
    const [currentZoom, setCurrentZoom] = useState(7); // Default zoom, will be updated by MapEvents and optimalZoom
    const [mapRef, setMapRef] = useState<any>(null);
    const [targetZoom, setTargetZoom] = useState<number | null>(null);
    const [scrollProgress, setScrollProgress] = useState(0); // 0 to 1 representing scroll progress
    const [hasUserScrolled, setHasUserScrolled] = useState(false); // Track if user has actually scrolled
    const [screenDimensions, setScreenDimensions] = useState({
        width: 1400,
        height: 800,
    });
    const [locationPositions, setLocationPositions] = useState<
        { top: number; center: number }[]
    >([]);
    const timelineRef = useRef<HTMLDivElement>(null);
    const locationRefs = useRef<(HTMLDivElement | null)[]>([]);
    const isClusterClickScrollingRef = useRef(false); // Use ref for immediate updates
    const clusterClickTimeoutRef = useRef<NodeJS.Timeout | null>(null); // Timeout for cluster clicks

    // FileViewer state
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentFileIndex, setCurrentFileIndex] = useState(0);
    const [viewerFiles, setViewerFiles] = useState<EnteFile[]>([]); // Files to show in viewer

    // Track screen dimensions for responsive zoom calculation
    useEffect(() => {
        const updateScreenDimensions = () => {
            if (typeof window !== "undefined") {
                setScreenDimensions({
                    width: window.innerWidth,
                    height: window.innerHeight,
                });
            }
        };

        // Set initial dimensions
        updateScreenDimensions();

        // Listen for window resize
        window.addEventListener("resize", updateScreenDimensions);

        return () => {
            window.removeEventListener("resize", updateScreenDimensions);
        };
    }, []);

    // FileViewer handlers
    const handleOpenFileViewer = useCallback(
        (_cluster: JourneyPoint[], clickedFileId: number) => {
            // Sort all files by creation time
            const sortedFiles = [...files].sort(
                (a, b) =>
                    new Date(a.metadata.creationTime / 1000).getTime() -
                    new Date(b.metadata.creationTime / 1000).getTime(),
            );

            // Find the index of the clicked photo in all files
            const clickedIndex = sortedFiles.findIndex(
                (f) => f.id === clickedFileId,
            );

            if (clickedIndex !== -1 && sortedFiles.length > 0) {
                setViewerFiles(sortedFiles);
                setCurrentFileIndex(clickedIndex);
                setOpenFileViewer(true);
                onSetOpenFileViewer?.(true);
            }
        },
        [files, onSetOpenFileViewer],
    );

    const handleCloseFileViewer = useCallback(() => {
        setOpenFileViewer(false);
        onSetOpenFileViewer?.(false);
    }, [onSetOpenFileViewer]);

    const handleTriggerRemotePull = useCallback(() => {
        return onRemotePull?.() || Promise.resolve();
    }, [onRemotePull]);

    // Geographic clustering with responsive distance thresholds and day separation
    const clusterPhotosByProximity = (photos: JourneyPoint[]) => {
        if (photos.length === 0) return [];

        // Mobile: no clustering for better timeline experience
        // Desktop: 1km clustering for cleaner map display
        const isMobile = screenDimensions.width < 768;
        if (isMobile) {
            // Return each photo as its own cluster on mobile
            return photos.map((photo) => [photo]);
        }

        // Desktop: 10km clustering distance (roughly 0.1 degrees)
        const distanceThreshold = 0.1; // About 10km in degrees

        // First, group photos by day
        const photosByDay = new Map<string, JourneyPoint[]>();
        photos.forEach((photo) => {
            const date = new Date(photo.timestamp);
            const dayKey = `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
            
            if (!photosByDay.has(dayKey)) {
                photosByDay.set(dayKey, []);
            }
            photosByDay.get(dayKey)!.push(photo);
        });

        // Then cluster within each day
        const allClusters: JourneyPoint[][] = [];
        
        photosByDay.forEach((dayPhotos) => {
            const visited = new Set<number>();
            
            dayPhotos.forEach((photo, i) => {
                if (visited.has(i)) return;

                const cluster = [photo];
                visited.add(i);

                dayPhotos.forEach((otherPhoto, j) => {
                    if (i === j || visited.has(j)) return;

                    const distance = Math.sqrt(
                        Math.pow(photo.lat - otherPhoto.lat, 2) +
                            Math.pow(photo.lng - otherPhoto.lng, 2),
                    );

                    if (distance < distanceThreshold) {
                        cluster.push(otherPhoto);
                        visited.add(j);
                    }
                });

                allClusters.push(cluster);
            });
        });

        return allClusters;
    };

    const photoClusters = useMemo(() => {
        const clusters = clusterPhotosByProximity(journeyData);

        // Sort clusters by their earliest timestamp to maintain chronological order
        return clusters.sort((a, b) => {
            const earliestA = Math.min(
                ...a.map((p) => new Date(p.timestamp).getTime()),
            );
            const earliestB = Math.min(
                ...b.map((p) => new Date(p.timestamp).getTime()),
            );
            return earliestA - earliestB;
        });
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [journeyData, screenDimensions]);

    // Calculate optimal zoom level based on cluster spread
    const optimalZoom = useMemo(() => {
        if (photoClusters.length === 0) return 7;

        // Calculate cluster centers
        const clusterCenters = photoClusters.map((cluster) => {
            const avgLat =
                cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
            const avgLng =
                cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;
            return { lat: avgLat, lng: avgLng };
        });

        // Find the bounding box of all clusters
        const allLats = clusterCenters.map((c) => c.lat);
        const allLngs = clusterCenters.map((c) => c.lng);
        const minLat = Math.min(...allLats);
        const maxLat = Math.max(...allLats);
        const minLng = Math.min(...allLngs);
        const maxLng = Math.max(...allLngs);

        // Calculate the span
        const latSpan = maxLat - minLat;
        const lngSpan = maxLng - minLng;
        const maxSpan = Math.max(latSpan, lngSpan);

        // Calculate minimum distances between clusters to avoid over-clustering
        let minDistance = Infinity;
        for (let i = 0; i < clusterCenters.length - 1; i++) {
            for (let j = i + 1; j < clusterCenters.length; j++) {
                const distance = Math.sqrt(
                    Math.pow(clusterCenters[i].lat - clusterCenters[j].lat, 2) +
                        Math.pow(
                            clusterCenters[i].lng - clusterCenters[j].lng,
                            2,
                        ),
                );
                minDistance = Math.min(minDistance, distance);
            }
        }

        // Calculate zoom based on cluster density and actual screen dimensions
        // Timeline takes more space on mobile (50%) vs desktop (50%)
        const isMobile = screenDimensions.width < 768;
        const timelineSizeRatio = isMobile ? 0.5 : 0.5;
        const visibleMapWidth =
            screenDimensions.width * (1 - timelineSizeRatio);

        // Calculate effective span considering cluster density
        // Sort clusters by longitude to find the core data area
        const sortedClusterLngs = allLngs.slice().sort((a, b) => a - b);
        const sortedClusterLats = allLats.slice().sort((a, b) => a - b);

        // Use 90th percentile span instead of full min/max to ignore outliers
        const p10Index = Math.floor(sortedClusterLngs.length * 0.1);
        const p90Index = Math.floor(sortedClusterLngs.length * 0.9);
        const effectiveLngSpan =
            sortedClusterLngs[p90Index] - sortedClusterLngs[p10Index];
        const effectiveLatSpan =
            sortedClusterLats[p90Index] - sortedClusterLats[p10Index];

        // Add more padding (40%) to prevent cropping at edges
        const paddedLngSpan = effectiveLngSpan * 1.4;
        const paddedLatSpan = effectiveLatSpan * 1.4;

        // Calculate zoom to fit the padded effective span
        const zoomForLngSpan = Math.log2(
            (visibleMapWidth * 360) / (paddedLngSpan * 256),
        );
        const visibleMapHeight = screenDimensions.height; // Full height available for map
        const zoomForLatSpan = Math.log2(
            (visibleMapHeight * 360) / (paddedLatSpan * 256),
        );

        // Take the more restrictive zoom
        const zoomToFitBounds = Math.min(zoomForLngSpan, zoomForLatSpan);

        // Also ensure reasonable cluster separation
        const targetPixelSeparation = 100;
        const pixelsPerDegreeAtOptimalZoom =
            targetPixelSeparation / minDistance;
        const optimalZoomFromSeparation = Math.log2(
            (pixelsPerDegreeAtOptimalZoom * 360) / 256,
        );

        // Prioritize fitting bounds with some buffer for cluster separation
        const calculatedZoom = Math.min(
            zoomToFitBounds,
            optimalZoomFromSeparation,
        );
        const clampedZoom = Math.max(6, Math.min(14, calculatedZoom));

        console.log(
            `🗺️  Cluster analysis: ${
                photoClusters.length
            } clusters, span: ${maxSpan.toFixed(
                4,
            )}°, minDistance: ${minDistance.toFixed(4)}°, screen: ${
                screenDimensions.width
            }x${screenDimensions.height}, optimalZoom: ${clampedZoom.toFixed(
                1,
            )}, effectiveSpan: ${effectiveLngSpan.toFixed(4)}°`,
        );

        return Math.round(clampedZoom);
    }, [photoClusters, screenDimensions]);

    // Update currentZoom when optimalZoom changes and there's no mapRef yet
    useEffect(() => {
        if (!mapRef && optimalZoom !== currentZoom) {
            console.log(
                `📊 Updating currentZoom from ${currentZoom} to optimalZoom ${optimalZoom} (no mapRef)`,
            );
            setCurrentZoom(optimalZoom);
        }
    }, [optimalZoom, mapRef, currentZoom]);

    useEffect(() => {
        setIsClient(true);

        // Process EnteFiles to extract location data
        const loadPhotosData = async () => {
            console.log("Starting to process EnteFiles...");
            const photoData: JourneyPoint[] = [];

            if (!files || files.length === 0) {
                console.warn("No files provided");
                setIsLoadingPhotos(false);
                return;
            }

            console.log(`Processing ${files.length} files`);

            // Process each EnteFile
            for (const file of files) {
                try {
                    // Extract location from metadata
                    const lat = file.metadata?.latitude;
                    const lng = file.metadata?.longitude;

                    if (lat && lng) {
                        // Get thumbnail URL for the file
                        const thumbnailUrl =
                            await downloadManager.renderableThumbnailURL(file);

                        photoData.push({
                            lat: lat,
                            lng: lng,
                            name: fileFileName(file), // Temporary name, will be updated after clustering
                            country: "Unknown",
                            timestamp: new Date(
                                file.metadata.creationTime / 1000,
                            ).toISOString(),
                            image: thumbnailUrl || "",
                            fileId: file.id,
                        });
                        console.log(
                            `Added ${fileFileName(file)} to journey data with lat: ${lat}, lng: ${lng}`,
                        );
                    } else {
                        console.log(`${fileFileName(file)} has no GPS data`);
                    }
                } catch (error) {
                    console.error(`Error processing file ${file.id}:`, error);
                }
            }

            console.log(`Total photos with GPS data: ${photoData.length}`);

            // Sort by timestamp
            photoData.sort(
                (a, b) =>
                    new Date(a.timestamp).getTime() -
                    new Date(b.timestamp).getTime(),
            );

            // Set journey data (location names will be fetched later)
            setJourneyData(photoData);
            setIsLoadingPhotos(false);

            // Set loading locations to true since we'll start fetching them
            if (photoData.length > 0) {
                setIsLoadingLocations(true);
                console.log(
                    "🔄 Will start loading locations for",
                    photoData.length,
                    "photos",
                );
            }

            console.log("Journey data set:", photoData);
        };

        loadPhotosData();
    }, [files]);

    // Fetch location names for clusters after they're created
    useEffect(() => {
        const fetchLocationNames = async () => {
            if (photoClusters.length === 0 || journeyData.length === 0) return;

            setIsLoadingLocations(true);
            console.log(
                "🔄 Started fetching location names for",
                photoClusters.length,
                "clusters",
            );

            // Create a map to track which photos have been updated
            const updatedPhotos = new Map<
                number,
                { name: string; country: string }
            >();

            // Get location names for each cluster center
            for (let i = 0; i < photoClusters.length; i++) {
                const cluster = photoClusters[i];
                if (!cluster || cluster.length === 0) continue;

                // Calculate cluster center
                const avgLat =
                    cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
                const avgLng =
                    cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;

                // Get location name for cluster center
                try {
                    const locationInfo = await getLocationName(
                        avgLat,
                        avgLng,
                        i + 1,
                    );

                    // Store the location info for all photos in this cluster
                    cluster.forEach((photo) => {
                        updatedPhotos.set(photo.fileId, {
                            name: locationInfo.place,
                            country: locationInfo.country,
                        });
                    });
                } catch (error) {
                    console.error(
                        `Error fetching location for cluster ${i}:`,
                        error,
                    );
                }
            }

            // Update journey data with location names
            if (updatedPhotos.size > 0) {
                setJourneyData((prevData) =>
                    prevData.map((photo) => {
                        const update = updatedPhotos.get(photo.fileId);
                        if (update) {
                            return { ...photo, ...update };
                        }
                        return photo;
                    }),
                );
            }

            setIsLoadingLocations(false);
            console.log("✅ Finished loading location names");
        };

        fetchLocationNames().catch((error) => {
            console.error("Error fetching location names:", error);
            setIsLoadingLocations(false);
            console.log("✅ Finished loading location names");
        });
        // Only run when photoClusters changes, not journeyData to avoid infinite loop
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [photoClusters.length]);

    // Cleanup timeout on unmount
    useEffect(() => {
        return () => {
            if (clusterClickTimeoutRef.current) {
                clearTimeout(clusterClickTimeoutRef.current);
                clusterClickTimeoutRef.current = null;
            }
        };
    }, []);

    // Function to create icon with specific image and progress styling
    const createIcon = (
        imageSrc: string,
        size = 40,
        borderColor = "#ffffff",
        _clusterCount?: number,
        isReached = false,
    ) => {
        if (typeof window === "undefined") return null;

        const L = require("leaflet");
        return L.divIcon({
            html: `
        <div class="photo-marker${isReached ? " reached" : ""}" style="
          width: ${size}px;
          height: ${size}px;
          border-radius: 50%;
          border: 3px solid ${
              isReached ? "rgba(34, 197, 94, 0.8)" : borderColor
          };
          overflow: hidden;
          background: white;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: ${
              isReached
                  ? "0 0 0 3px rgba(34, 197, 94, 0.3), 0 0 0 6px rgba(34, 197, 94, 0.15), 0 2px 4px rgba(0,0,0,0.3)"
                  : "0 2px 4px rgba(0,0,0,0.3)"
          };
          position: relative;
          transition: all 0.3s ease;
          cursor: pointer;
        "
        onmouseover="this.style.borderColor='${
            isReached ? "rgba(34, 197, 94, 0.8)" : "#10B981"
        }';"
        onmouseout="this.style.borderColor='${
            isReached ? "rgba(34, 197, 94, 0.8)" : "#ffffff"
        }';"
        >
          <img 
            src="${imageSrc}" 
            style="
              width: 100%;
              height: 100%;
              object-fit: cover;
              border-radius: 50%;
            "
            alt="Location"
          />
        </div>
      `,
            className: "custom-image-marker",
            iconSize: [size, size],
            iconAnchor: [size / 2, size / 2],
            popupAnchor: [0, -size / 2],
        });
    };

    // Function to create super-cluster icon with badge
    const createSuperClusterIcon = (
        imageSrc: string,
        clusterCount: number,
        size = 45,
        isReached = false,
    ) => {
        if (typeof window === "undefined") return null;

        const L = require("leaflet");
        const containerSize = size + 28;

        return L.divIcon({
            html: `
        <div class="super-cluster-container" style="
          width: ${containerSize}px;
          height: ${containerSize}px;
          position: relative;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        ">
          <div class="super-cluster-marker${
              isReached ? " reached" : ""
          }" style="
            width: ${size}px;
            height: ${size}px;
            border-radius: 50%;
            border: 3px solid ${
                isReached ? "rgba(34, 197, 94, 0.8)" : "#ffffff"
            };
            overflow: hidden;
            background: white;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: ${
                isReached
                    ? "0 0 0 3px rgba(34, 197, 94, 0.3), 0 0 0 6px rgba(34, 197, 94, 0.15), 0 4px 8px rgba(0,0,0,0.25)"
                    : "0 4px 8px rgba(0,0,0,0.25)"
            };
            position: relative;
            transition: all 0.2s ease;
          "
          onmouseover="this.style.borderColor='${
              isReached ? "rgba(34, 197, 94, 0.8)" : "#10B981"
          }';"
          onmouseout="this.style.borderColor='${
              isReached ? "rgba(34, 197, 94, 0.8)" : "#ffffff"
          }';"
          >
            <img 
              src="${imageSrc}" 
              style="
                width: 100%;
                height: 100%;
                object-fit: cover;
                border-radius: 50%;
              "
              alt="Location"
            />
          </div>
          <div style="
            position: absolute;
            top: 10px;
            right: 10px;
            background: #000000;
            color: white;
            border-radius: 50%;
            width: 22px;
            height: 22px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 600;
            padding: 0 0 0 1px;
            border: 2px solid white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
          ">${clusterCount}</div>
        </div>
      `,
            className: "super-cluster-marker",
            iconSize: [containerSize, containerSize],
            iconAnchor: [containerSize / 2, containerSize / 2],
            popupAnchor: [0, -size / 2],
        });
    };

    // Calculate super-clusters based on screen collisions
    const { superClusters, visibleClusters } = useMemo(() => {
        const detectScreenCollisions = (
            clusters: JourneyPoint[][],
            zoom: number,
        ) => {
            // Use target zoom if we're in the middle of a zoom animation, otherwise use optimal zoom
            const effectiveZoom =
                targetZoom !== null ? targetZoom : mapRef ? zoom : optimalZoom;

            // Convert geographic distance to screen pixels
            // At zoom Z, roughly 2^Z * 256 pixels per 360 degrees
            const pixelsPerDegree = (Math.pow(2, effectiveZoom) * 256) / 360;
            // Use a more conservative collision threshold to show more individual clusters
            const collisionThreshold = 50 / pixelsPerDegree; // 50 pixel collision radius

            const superClusters: {
                lat: number;
                lng: number;
                clusterCount: number;
                clustersInvolved: number[];
                image: string;
            }[] = [];
            const hiddenClusterIndices = new Set<number>();

            // Check each cluster against others for screen-space collision
            clusters.forEach((cluster, i) => {
                if (hiddenClusterIndices.has(i)) return;

                const clusterLat =
                    cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
                const clusterLng =
                    cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;

                const overlappingClusters = [i];

                clusters.forEach((otherCluster, j) => {
                    if (i === j || hiddenClusterIndices.has(j)) return;

                    const otherLat =
                        otherCluster.reduce((sum, p) => sum + p.lat, 0) /
                        otherCluster.length;
                    const otherLng =
                        otherCluster.reduce((sum, p) => sum + p.lng, 0) /
                        otherCluster.length;

                    const distance = Math.sqrt(
                        Math.pow(clusterLat - otherLat, 2) +
                            Math.pow(clusterLng - otherLng, 2),
                    );

                    if (distance < collisionThreshold) {
                        overlappingClusters.push(j);
                        hiddenClusterIndices.add(j);
                    }
                });

                // If we found overlapping clusters, create a super-cluster
                if (overlappingClusters.length > 1) {
                    hiddenClusterIndices.add(i); // Hide the original cluster too

                    // Calculate center position of all overlapping clusters
                    let totalLat = 0,
                        totalLng = 0;
                    overlappingClusters.forEach((idx) => {
                        const c = clusters[idx];
                        totalLat +=
                            c.reduce((sum, p) => sum + p.lat, 0) / c.length;
                        totalLng +=
                            c.reduce((sum, p) => sum + p.lng, 0) / c.length;
                    });

                    // Get the first photo from the first cluster as representative image
                    const representativePhoto =
                        clusters[overlappingClusters[0]][0];

                    superClusters.push({
                        lat: totalLat / overlappingClusters.length,
                        lng: totalLng / overlappingClusters.length,
                        clusterCount: overlappingClusters.length,
                        clustersInvolved: overlappingClusters,
                        image: representativePhoto.image,
                    });
                }
            });

            // Return visible clusters (those not hidden by super-clusters)
            const visibleClusters = clusters.filter(
                (_, idx) => !hiddenClusterIndices.has(idx),
            );

            return { superClusters, visibleClusters };
        };

        const result = detectScreenCollisions(photoClusters, currentZoom);
        console.log(
            `🔍 Super-cluster detection: ${
                result.superClusters.length
            } super-clusters, ${
                result.visibleClusters.length
            } visible clusters, currentZoom: ${currentZoom}, optimalZoom: ${optimalZoom}, mapRef: ${!!mapRef}`,
        );
        return result;
    }, [photoClusters, currentZoom, mapRef, targetZoom, optimalZoom]);

    // Update location positions when layout changes
    const updateLocationPositions = useCallback(() => {
        if (locationRefs.current.length === 0) return;

        const positions = locationRefs.current.map((ref) => {
            if (!ref) return { top: 0, center: 0 };
            const rect = ref.getBoundingClientRect();
            const top = ref.offsetTop;
            const center = top + rect.height / 2;
            return { top, center };
        });

        setLocationPositions(positions);
    }, []);

    // Calculate scroll progress based on timeline scroll position and update map center
    const handleTimelineScroll = useCallback(() => {
        if (
            !timelineRef.current ||
            photoClusters.length === 0 ||
            locationPositions.length === 0
        )
            return;

        const timelineContainer = timelineRef.current;
        const scrollHeight = timelineContainer.scrollHeight;
        const clientHeight = timelineContainer.clientHeight;
        const scrollTop = timelineContainer.scrollTop;

        // Calculate current progress based on scroll position
        const isAtBottom = scrollTop + clientHeight >= scrollHeight - 10;
        let progress = 0;
        if (isAtBottom) {
            progress = 1;
        } else {
            const maxScrollableDistance = scrollHeight - clientHeight;
            if (maxScrollableDistance > 0) {
                progress = scrollTop / maxScrollableDistance;
            } else {
                progress = 0;
            }
        }
        const clampedProgress = Math.min(1, Math.max(0, progress));

        // Don't update progress during cluster click scrolling - keep the set value
        if (isClusterClickScrollingRef.current) {
            return;
        }

        // Normal scroll handling - mark that user has scrolled
        setHasUserScrolled(true);
        setScrollProgress(clampedProgress);

        // Real-time map center update based on scroll progress
        if (mapRef && !isClusterClickScrollingRef.current) {
            const clusterCenters = photoClusters.map((cluster) => {
                const avgLat =
                    cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
                const avgLng =
                    cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;
                return { lat: avgLat, lng: avgLng };
            });

            if (clusterCenters.length > 0) {
                let targetLat, targetLng;

                // Always start at first cluster (journey always starts at first location)
                if (clampedProgress <= 0) {
                    // At the start, focus on first cluster
                    targetLat = clusterCenters[0].lat;
                    targetLng = clusterCenters[0].lng;
                } else if (clampedProgress === 1) {
                    // At the end, focus on last cluster
                    targetLat = clusterCenters[clusterCenters.length - 1].lat;
                    targetLng = clusterCenters[clusterCenters.length - 1].lng;
                } else {
                    // Interpolate between clusters based on progress
                    const clusterProgress =
                        clampedProgress * (clusterCenters.length - 1);
                    const currentClusterIndex = Math.floor(clusterProgress);
                    const nextClusterIndex = Math.min(
                        currentClusterIndex + 1,
                        clusterCenters.length - 1,
                    );
                    const lerpFactor = clusterProgress - currentClusterIndex;

                    const currentCluster = clusterCenters[currentClusterIndex];
                    const nextCluster = clusterCenters[nextClusterIndex];

                    if (!currentCluster || !nextCluster) {
                        targetLat = clusterCenters[0]?.lat || 0;
                        targetLng = clusterCenters[0]?.lng || 0;
                    } else {
                        // Linear interpolation between clusters
                        targetLat =
                            currentCluster.lat +
                            (nextCluster.lat - currentCluster.lat) * lerpFactor;
                        targetLng =
                            currentCluster.lng +
                            (nextCluster.lng - currentCluster.lng) * lerpFactor;
                    }
                }

                // Apply the offset for timeline positioning (same logic as getMapCenter)
                const isMobile = screenDimensions.width < 768;
                const timelineSizeRatio = isMobile ? 0.5 : 0.5;

                // Calculate the span and shift for centering in visible area
                const allLngs = clusterCenters.map((c) => c.lng);
                const minLng = Math.min(...allLngs);
                const maxLng = Math.max(...allLngs);
                const lngSpan = maxLng - minLng;
                const paddedSpan = Math.max(lngSpan * 1.4, 0.1); // Minimum span for single locations

                const mapSizeRatio = 1 - timelineSizeRatio;
                const screenWidthInDegrees = paddedSpan / mapSizeRatio;
                const shiftAmount =
                    screenWidthInDegrees * (timelineSizeRatio / 2);

                const adjustedLng = targetLng - shiftAmount;

                // Get current zoom level
                const currentMapZoom = mapRef.getZoom();

                // Always return to optimal zoom when scrolling timeline
                if (currentMapZoom !== optimalZoom) {
                    // Zoom back to default/optimal zoom while panning
                    mapRef.flyTo([targetLat, adjustedLng], optimalZoom, {
                        animate: true,
                        duration: 0.5,
                        easeLinearity: 0.5,
                    });
                } else {
                    // Just pan when already at optimal zoom
                    mapRef.panTo([targetLat, adjustedLng], {
                        animate: true,
                        duration: 0.3,
                        easeLinearity: 0.8,
                    });
                }
            }
        }

        console.log("Scroll Progress Debug:", {
            calculatedProgress: clampedProgress,
            scrollTop,
            isClusterClickScrolling: isClusterClickScrollingRef.current,
        });
    }, [
        timelineRef,
        photoClusters,
        locationPositions,
        mapRef,
        screenDimensions,
        optimalZoom,
    ]);

    // Update positions when locations render
    useEffect(() => {
        if (
            locationRefs.current.length === photoClusters.length &&
            photoClusters.length > 0
        ) {
            // Small delay to ensure layout is complete
            const timer = setTimeout(updateLocationPositions, 100);
            return () => clearTimeout(timer);
        }
    }, [photoClusters, updateLocationPositions]);

    // Add scroll event listener to timeline - real-time, no debounce
    useEffect(() => {
        const timelineContainer = timelineRef.current;
        if (!timelineContainer) return;

        timelineContainer.addEventListener("scroll", handleTimelineScroll);

        // Trigger initial scroll progress calculation after a brief delay to ensure layout is complete
        setTimeout(() => {
            handleTimelineScroll();
        }, 50);

        return () => {
            timelineContainer.removeEventListener(
                "scroll",
                handleTimelineScroll,
            );
        };
    }, [handleTimelineScroll]);

    // Function to scroll timeline to specific location
    const scrollTimelineToLocation = useCallback(
        (locationIndex: number) => {
            if (
                !timelineRef.current ||
                locationIndex < 0 ||
                locationIndex >= photoClusters.length ||
                locationPositions.length === 0
            )
                return;

            const timelineContainer = timelineRef.current;
            const scrollHeight = timelineContainer.scrollHeight;
            const clientHeight = timelineContainer.clientHeight;
            const maxScrollableDistance = scrollHeight - clientHeight;

            // Calculate what scroll position would give us progress to this location
            // We want progress = locationIndex / (totalLocations - 1)
            const targetProgress =
                locationIndex / Math.max(1, photoClusters.length - 1);
            const targetScrollTop = targetProgress * maxScrollableDistance;

            // Note: scroll progress is now set in the click handler before calling this function
            // to ensure immediate visual feedback

            // Smooth scroll to the calculated position
            timelineContainer.scrollTo({
                top: Math.max(
                    0,
                    Math.min(targetScrollTop, maxScrollableDistance),
                ),
                behavior: "smooth",
            });
        },
        [photoClusters, timelineRef, locationPositions],
    );

    // Calculate map center - start at first location to match timeline initial state
    const getMapCenter = (): [number, number] => {
        // If no clusters yet, check journey data
        if (photoClusters.length === 0) {
            const firstPoint = journeyData[0];
            if (!firstPoint) return [0, 0]; // Fallback, but map won't render anyway
            return [firstPoint.lat, firstPoint.lng];
        }

        // Start at first cluster center to match the timeline starting position
        const firstCluster = photoClusters[0];
        if (!firstCluster || firstCluster.length === 0) return [0, 0]; // Fallback, but map won't render anyway

        const firstLat =
            firstCluster.reduce((sum, p) => sum + p.lat, 0) /
            firstCluster.length;
        const firstLng =
            firstCluster.reduce((sum, p) => sum + p.lng, 0) /
            firstCluster.length;

        // Calculate shift for timeline positioning
        const clusterCenters = photoClusters.map((cluster) => {
            const avgLat =
                cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
            const avgLng =
                cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;
            return { lat: avgLat, lng: avgLng };
        });

        const allLngs = clusterCenters.map((c) => c.lng);
        const minLng = Math.min(...allLngs);
        const maxLng = Math.max(...allLngs);
        const lngSpan = maxLng - minLng;
        const paddedSpan = Math.max(lngSpan * 1.4, 0.1); // Minimum span for single locations

        const isMobile = screenDimensions.width < 768;
        const timelineSizeRatio = isMobile ? 0.5 : 0.5;
        const mapSizeRatio = 1 - timelineSizeRatio;

        const screenWidthInDegrees = paddedSpan / mapSizeRatio;
        const shiftAmount = screenWidthInDegrees * (timelineSizeRatio / 2);

        // Shift the first location left so it appears centered in visible area
        const adjustedLng = firstLng - shiftAmount;

        return [firstLat, adjustedLng];
    };

    // Only wait for client-side rendering (needed for maps), but show layout immediately
    // Let individual components handle their own loading states
    if (!isClient) {
        return null; // SSR compatibility
    }

    // Show black background if no photo data yet
    const hasPhotoData = journeyData.length > 0;

    return (
        <div style={{ position: "relative", width: "100%", height: "100%" }}>
            {/* Left Sidebar - Floating Timeline */}
            <div
                ref={timelineRef}
                style={{
                    position: "absolute",
                    left: "16px",
                    top: "16px",
                    bottom: "16px",
                    width: "min(50%, 1000px)",
                    overflow: "auto",
                    boxShadow:
                        "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
                    backgroundColor: "white",
                    zIndex: 1000,
                    borderRadius: "32px",
                }}
            >
                {isLoadingPhotos ? (
                    <div
                        style={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            height: "100%",
                        }}
                    >
                        <div
                            style={{
                                animation: "spin 1s linear infinite",
                                borderRadius: "50%",
                                height: "48px",
                                width: "48px",
                                borderBottom: "2px solid #3b82f6",
                            }}
                        ></div>
                    </div>
                ) : (
                    <div style={{ padding: "32px" }}>
                        {journeyData.length > 0 ? (
                            <div>
                                <TripCover
                                    journeyData={journeyData}
                                    photoClusters={photoClusters}
                                    albumTitle={collectionTitle}
                                    ownerName={collectionOwner}
                                />

                                {/* Show either loading spinner or trip started section + timeline */}
                                {isLoadingLocations ? (
                                    <div
                                        style={{
                                            display: "flex",
                                            justifyContent: "center",
                                            alignItems: "center",
                                            padding: "60px 20px",
                                            minHeight: "200px",
                                        }}
                                    >
                                        <div
                                            style={{
                                                animation:
                                                    "spin 1s linear infinite",
                                                borderRadius: "50%",
                                                height: "40px",
                                                width: "40px",
                                                borderTop: "3px solid #10b981",
                                                borderRight:
                                                    "3px solid transparent",
                                                borderBottom:
                                                    "3px solid #10b981",
                                                borderLeft:
                                                    "3px solid transparent",
                                            }}
                                        ></div>
                                    </div>
                                ) : (
                                    <>
                                        <TripStartedSection
                                            journeyData={journeyData}
                                        />

                                        {/* Timeline */}
                                        <div
                                            style={{ position: "relative" }}
                                            id="timeline-container"
                                        >
                                            <TimelineBaseLine
                                                locationPositions={
                                                    locationPositions
                                                }
                                            />

                                            <TimelineProgressLine
                                                locationPositions={
                                                    locationPositions
                                                }
                                                scrollProgress={scrollProgress}
                                                hasUserScrolled={
                                                    hasUserScrolled
                                                }
                                                photoClusters={photoClusters}
                                            />

                                            {photoClusters.map(
                                                (cluster, index) => (
                                                    <TimelineLocation
                                                        key={index}
                                                        cluster={cluster}
                                                        index={index}
                                                        photoClusters={
                                                            photoClusters
                                                        }
                                                        scrollProgress={
                                                            scrollProgress
                                                        }
                                                        journeyData={
                                                            journeyData
                                                        }
                                                        onRef={(el) => {
                                                            locationRefs.current[
                                                                index
                                                            ] = el;
                                                        }}
                                                        onPhotoClick={
                                                            handleOpenFileViewer
                                                        }
                                                    />
                                                ),
                                            )}

                                            {/* Bottom padding for scrolling */}
                                            <div
                                                style={{ marginBottom: "24px" }}
                                            ></div>
                                        </div>
                                    </>
                                )}
                            </div>
                        ) : (
                            <div style={{ textAlign: "center" }}>
                                <p style={{ color: "#4b5563" }}>
                                    No photos with location data found.
                                </p>
                            </div>
                        )}
                    </div>
                )}
            </div>

            {/* Map Container */}
            <div
                style={{
                    width: "100%",
                    height: "100%",
                    backgroundColor: hasPhotoData ? "transparent" : "#000000",
                }}
            >
                {hasPhotoData ? (
                    <MapContainer
                        center={getMapCenter()}
                        zoom={optimalZoom}
                        style={{ width: "100%", height: "100%" }}
                        scrollWheelZoom={true}
                        zoomControl={false}
                    >
                        <MapEvents
                            setMapRef={setMapRef}
                            setCurrentZoom={setCurrentZoom}
                            setTargetZoom={setTargetZoom}
                        />
                        {/* Stadia Alidade Satellite - includes both imagery and labels */}
                        <TileLayer
                            attribution='&copy; <a href="https://stadiamaps.com/">Stadia Maps</a>, &copy; <a href="https://openmaptiles.org/">OpenMapTiles</a> &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
                            url="https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.jpg"
                            maxZoom={20}
                        />

                        {/* Draw super-clusters (clickable for zoom and gallery) */}
                        {superClusters.map((superCluster, index) => {
                            // Get all photos from all clusters involved in this supercluster
                            const allPhotosInSuperCluster =
                                superCluster.clustersInvolved.flatMap(
                                    (clusterIdx) => photoClusters[clusterIdx],
                                );

                            // Find the most recent photo/place
                            const mostRecentPhotos = [
                                ...allPhotosInSuperCluster,
                            ].sort(
                                (a, b) =>
                                    new Date(b.timestamp).getTime() -
                                    new Date(a.timestamp).getTime(),
                            );

                            // Check if this super-cluster has been reached
                            const firstClusterIndex =
                                superCluster.clustersInvolved[0];
                            const isReached =
                                scrollProgress >=
                                firstClusterIndex /
                                    Math.max(1, photoClusters.length - 1);

                            return (
                                <Marker
                                    key={`super-cluster-${index}`}
                                    position={[
                                        superCluster.lat,
                                        superCluster.lng,
                                    ]}
                                    icon={createSuperClusterIcon(
                                        mostRecentPhotos[0].image, // Use most recent photo for display
                                        superCluster.clusterCount,
                                        45,
                                        isReached,
                                    )}
                                    eventHandlers={{
                                        click: () => {
                                            const firstClusterIndex =
                                                superCluster
                                                    .clustersInvolved[0];

                                            // Calculate target progress for immediate update
                                            const targetProgress =
                                                firstClusterIndex /
                                                Math.max(
                                                    1,
                                                    photoClusters.length - 1,
                                                );

                                            // Clear any existing timeout
                                            if (
                                                clusterClickTimeoutRef.current
                                            ) {
                                                clearTimeout(
                                                    clusterClickTimeoutRef.current,
                                                );
                                            }

                                            // Block scroll handler during cluster click
                                            isClusterClickScrollingRef.current = true;

                                            // Immediately update scroll progress to show green state
                                            setScrollProgress(targetProgress);

                                            // Center super cluster in the visible area
                                            // Use same logic as timeline scroll for consistent positioning
                                            const allClusterLngs =
                                                photoClusters.map(
                                                    (cluster) =>
                                                        cluster.reduce(
                                                            (sum, p) =>
                                                                sum + p.lng,
                                                            0,
                                                        ) / cluster.length,
                                                );
                                            const minLng = Math.min(
                                                ...allClusterLngs,
                                            );
                                            const maxLng = Math.max(
                                                ...allClusterLngs,
                                            );
                                            const lngSpan = maxLng - minLng;
                                            const paddedSpan = Math.max(
                                                lngSpan * 1.4,
                                                0.1,
                                            ); // Same as timeline scroll

                                            const isMobile =
                                                screenDimensions.width < 768;
                                            const timelineSizeRatio = isMobile
                                                ? 0.5
                                                : 0.5;
                                            const mapSizeRatio =
                                                1 - timelineSizeRatio;
                                            const screenWidthInDegrees =
                                                paddedSpan / mapSizeRatio;
                                            const shiftAmount =
                                                screenWidthInDegrees *
                                                (timelineSizeRatio / 2);
                                            const offsetLng =
                                                superCluster.lng - shiftAmount;
                                            if (mapRef) {
                                                mapRef.panTo(
                                                    [
                                                        superCluster.lat,
                                                        offsetLng,
                                                    ],
                                                    {
                                                        animate: true,
                                                        duration: 1.0,
                                                    },
                                                );
                                            }

                                            // Start timeline scrolling and set timeout to re-enable handler
                                            setTimeout(() => {
                                                scrollTimelineToLocation(
                                                    firstClusterIndex,
                                                );
                                            }, 50);

                                            // Re-enable scroll handler after animation completes
                                            clusterClickTimeoutRef.current =
                                                setTimeout(() => {
                                                    isClusterClickScrollingRef.current = false;
                                                    clusterClickTimeoutRef.current =
                                                        null;
                                                }, 1500);
                                        },
                                    }}
                                />
                            );
                        })}

                        {/* Draw visible regular clusters */}
                        {visibleClusters.map((cluster, index) => {
                            const firstPhoto = cluster[0];
                            const avgLat =
                                cluster.reduce((sum, p) => sum + p.lat, 0) /
                                cluster.length;
                            const avgLng =
                                cluster.reduce((sum, p) => sum + p.lng, 0) /
                                cluster.length;

                            // Find the original cluster index
                            const originalClusterIndex =
                                photoClusters.findIndex(
                                    (originalCluster) =>
                                        originalCluster.length ===
                                            cluster.length &&
                                        originalCluster[0].image ===
                                            cluster[0].image,
                                );
                            // Check if this location has been reached based on progress
                            const isReached =
                                scrollProgress >=
                                originalClusterIndex /
                                    Math.max(1, photoClusters.length - 1);

                            return (
                                <Marker
                                    key={`cluster-${index}`}
                                    position={[avgLat, avgLng]}
                                    icon={createIcon(
                                        firstPhoto.image,
                                        45,
                                        "#ffffff",
                                        cluster.length,
                                        isReached,
                                    )}
                                    eventHandlers={{
                                        click: () => {
                                            // Calculate target progress for immediate update
                                            const targetProgress =
                                                originalClusterIndex /
                                                Math.max(
                                                    1,
                                                    photoClusters.length - 1,
                                                );

                                            // Clear any existing timeout
                                            if (
                                                clusterClickTimeoutRef.current
                                            ) {
                                                clearTimeout(
                                                    clusterClickTimeoutRef.current,
                                                );
                                            }

                                            // Block scroll handler during cluster click
                                            isClusterClickScrollingRef.current = true;

                                            // Immediately update scroll progress to show green state
                                            setScrollProgress(targetProgress);

                                            // Get cluster center and pan map directly
                                            const avgLat =
                                                cluster.reduce(
                                                    (sum, p) => sum + p.lat,
                                                    0,
                                                ) / cluster.length;
                                            const avgLng =
                                                cluster.reduce(
                                                    (sum, p) => sum + p.lng,
                                                    0,
                                                ) / cluster.length;
                                            // Use same logic as timeline scroll for consistent positioning
                                            const allClusterLngs =
                                                photoClusters.map(
                                                    (cluster) =>
                                                        cluster.reduce(
                                                            (sum, p) =>
                                                                sum + p.lng,
                                                            0,
                                                        ) / cluster.length,
                                                );
                                            const minLng = Math.min(
                                                ...allClusterLngs,
                                            );
                                            const maxLng = Math.max(
                                                ...allClusterLngs,
                                            );
                                            const lngSpan = maxLng - minLng;
                                            const paddedSpan = Math.max(
                                                lngSpan * 1.4,
                                                0.1,
                                            ); // Same as timeline scroll

                                            const isMobile =
                                                screenDimensions.width < 768;
                                            const timelineSizeRatio = isMobile
                                                ? 0.5
                                                : 0.5;
                                            const mapSizeRatio =
                                                1 - timelineSizeRatio;
                                            const screenWidthInDegrees =
                                                paddedSpan / mapSizeRatio;
                                            const shiftAmount =
                                                screenWidthInDegrees *
                                                (timelineSizeRatio / 2);
                                            const offsetLng =
                                                avgLng - shiftAmount;

                                            if (mapRef) {
                                                if (
                                                    mapRef.getZoom() >
                                                    optimalZoom
                                                ) {
                                                    mapRef.flyTo(
                                                        [avgLat, offsetLng],
                                                        optimalZoom,
                                                        {
                                                            animate: true,
                                                            duration: 1.2,
                                                            easeLinearity: 0.25,
                                                        },
                                                    );
                                                } else {
                                                    mapRef.panTo(
                                                        [avgLat, offsetLng],
                                                        {
                                                            animate: true,
                                                            duration: 1.0,
                                                        },
                                                    );
                                                }
                                            }

                                            // Start timeline scrolling and set timeout to re-enable handler
                                            setTimeout(() => {
                                                scrollTimelineToLocation(
                                                    originalClusterIndex,
                                                );
                                            }, 50);

                                            // Re-enable scroll handler after animation completes
                                            clusterClickTimeoutRef.current =
                                                setTimeout(() => {
                                                    isClusterClickScrollingRef.current = false;
                                                    clusterClickTimeoutRef.current =
                                                        null;
                                                }, 1500);
                                        },
                                    }}
                                />
                            );
                        })}
                    </MapContainer>
                ) : null}
            </div>

            {/* FileViewer for photo gallery */}
            <FileViewer
                open={openFileViewer}
                onClose={handleCloseFileViewer}
                initialIndex={currentFileIndex}
                files={viewerFiles}
                user={user}
                disableDownload={!enableDownload}
                onTriggerRemotePull={handleTriggerRemotePull}
                // Add minimal required props - can be extended based on needs
                isInIncomingSharedCollection={false}
                isInHiddenSection={false}
                fileNormalCollectionIDs={new Map()}
                collectionNameByID={new Map()}
                favoriteFileIDs={new Set<number>()}
                pendingFavoriteUpdates={new Set<number>()}
                pendingVisibilityUpdates={new Set<number>()}
                onRemoteFilesPull={handleTriggerRemotePull}
                onVisualFeedback={() => {}}
                onToggleFavorite={() => Promise.resolve()}
                onFileVisibilityUpdate={() => Promise.resolve()}
                onSelectCollection={() => {}}
                onSelectPerson={() => {}}
                onDownload={() => {}}
                onDelete={() => Promise.resolve()}
                onSaveEditedImageCopy={() => {}}
            />
        </div>
    );
};
