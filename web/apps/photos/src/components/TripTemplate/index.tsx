import { DownloadStatusNotifications } from "components/DownloadStatusNotifications";
import { useSaveGroups } from "ente-gallery/components/utils/save-groups";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { downloadManager } from "ente-gallery/services/download";
import { downloadAndSaveCollectionFiles } from "ente-gallery/services/save";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import L from "leaflet";
import {
    startTransition,
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";

// Import extracted components
import { TimelineBaseLine } from "./TimelineBaseLine";
import { TimelineLocation } from "./TimelineLocation";
import { TimelineProgressLine } from "./TimelineProgressLine";
import { TopNavButtons } from "./TopNavButtons";
import { TripCover } from "./TripCover";
import { TripMap } from "./TripMap";
import { TripStartedSection } from "./TripStartedSection";

// Import hooks
import { useFileViewer } from "./useFileViewer";

// Import types and utils
import { calculateOptimalZoom, clusterPhotosByProximity } from "./mapHelpers";
import type { JourneyPoint } from "./types";
import { getLocationName, throttle } from "./utils";

interface TripTemplateProps {
    files: EnteFile[];
    collection?: Collection;
    albumTitle?: string;
    user?: { id: number; email: string; token: string; [key: string]: unknown }; // User object for FileViewer
    // FileViewer related props (optional, can be added as needed)
    enableDownload?: boolean;
    onSetOpenFileViewer?: (open: boolean) => void;
    onRemotePull?: () => Promise<void>;
    onAddPhotos?: () => void; // Callback for add photos button
}

export const TripTemplate: React.FC<TripTemplateProps> = ({
    files,
    collection,
    albumTitle,
    user,
    enableDownload,
    onSetOpenFileViewer,
    onRemotePull,
    onAddPhotos,
}) => {
    // Extract collection info if available
    const collectionTitle = collection?.name || albumTitle || "Trip";

    // Save groups hook for download progress tracking
    const { saveGroups, onAddSaveGroup, onRemoveSaveGroup } = useSaveGroups();

    // File viewer hook
    const {
        openFileViewer,
        currentFileIndex,
        viewerFiles,
        handleOpenFileViewer,
        handleCloseFileViewer,
        handleTriggerRemotePull,
    } = useFileViewer({ files, onSetOpenFileViewer, onRemotePull });

    // Download all files functionality
    const downloadAllFiles = () => {
        if (!collection) return;
        void downloadAndSaveCollectionFiles(
            collectionTitle,
            collection.id,
            files,
            undefined,
            onAddSaveGroup,
        );
    };
    // Add CSS animation for spinner
    useEffect(() => {
        if (typeof document !== "undefined") {
            const style = document.createElement("style");
            style.textContent = `
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        @keyframes fadeInOut {
          0% { opacity: 0; transform: translateY(-10px); }
          15%, 85% { opacity: 1; transform: translateY(0); }
          100% { opacity: 0; transform: translateY(-10px); }
        }
        .photo-fan-hover {
          transition: transform 0.3s ease-in-out;
          cursor: pointer;
        }
        .photo-fan-hover:hover {
          transform: scale(1.05);
        }
      `;
            document.head.appendChild(style);
            return () => {
                document.head.removeChild(style);
            };
        }
        return undefined;
    }, []);

    const [journeyData, setJourneyData] = useState<JourneyPoint[]>([]);
    const [coverImageUrl, setCoverImageUrl] = useState<string | null>(null);
    const [isClient, setIsClient] = useState(false);
    const [isLoadingLocations, setIsLoadingLocations] = useState(false);
    const [isInitialLoad, setIsInitialLoad] = useState(true);
    const [currentZoom, setCurrentZoom] = useState(7); // Default zoom, will be updated by MapEvents and optimalZoom
    const [mapRef, setMapRef] = useState<L.Map | null>(null);
    const [targetZoom, setTargetZoom] = useState<number | null>(null);
    const [scrollProgress, setScrollProgress] = useState(0); // 0 to 1 representing scroll progress
    const [hasUserScrolled, setHasUserScrolled] = useState(false); // Track if user has actually scrolled
    const [screenDimensions, setScreenDimensions] = useState<{
        width: number;
        height: number;
    }>({ width: 1400, height: 800 });
    const [locationPositions, setLocationPositions] = useState<
        { top: number; center: number }[]
    >([]);
    const timelineRef = useRef<HTMLDivElement>(null);
    const locationRefs = useRef<(HTMLDivElement | null)[]>([]);
    const isClusterClickScrollingRef = useRef(false); // Use ref for immediate updates
    const clusterClickTimeoutRef = useRef<NodeJS.Timeout | null>(null); // Timeout for cluster clicks
    const thumbnailsGeneratedRef = useRef(false); // Track if thumbnails have been generated
    const locationDataRef = useRef<
        Map<number, { name: string; country: string }>
    >(new Map()); // Track location data to prevent resets
    const filesCountRef = useRef<number>(0); // Track files count to detect real changes

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

    const photoClusters = useMemo(() => {
        const clusters = clusterPhotosByProximity(
            journeyData,
            screenDimensions,
        );

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
    }, [journeyData, screenDimensions]);

    // Calculate optimal zoom level based on cluster spread
    const optimalZoom = useMemo(() => {
        return calculateOptimalZoom(photoClusters, screenDimensions);
    }, [photoClusters, screenDimensions]);

    // Update currentZoom when optimalZoom changes and there's no mapRef yet
    useEffect(() => {
        if (!mapRef && optimalZoom !== currentZoom) {
            setCurrentZoom(optimalZoom);
        }
    }, [optimalZoom, mapRef, currentZoom]);

    useEffect(() => {
        setIsClient(true);

        // Check if the files count has actually changed (not just array reference)
        const hasFilesCountChanged = files.length !== filesCountRef.current;
        filesCountRef.current = files.length;

        // Only reload data if the count changed or this is the initial load
        if (!hasFilesCountChanged && journeyData.length > 0) {
            return;
        }

        // Reset thumbnail generation flag when files change
        thumbnailsGeneratedRef.current = false;

        // Process EnteFiles to extract location data
        const loadPhotosData = () => {
            const photoData: JourneyPoint[] = [];

            if (files.length === 0) {
                return;
            }

            // Use cached location data to preserve location names

            // Process each EnteFile (without thumbnails first)
            for (const file of files) {
                try {
                    // Extract location from metadata
                    const lat = file.metadata.latitude;
                    const lng = file.metadata.longitude;

                    if (lat && lng) {
                        // Check if we have cached location data for this file
                        const cachedLocation = locationDataRef.current.get(
                            file.id,
                        );
                        const finalName =
                            cachedLocation?.name || fileFileName(file);
                        const finalCountry =
                            cachedLocation?.country || "Unknown";

                        photoData.push({
                            lat: lat,
                            lng: lng,
                            name: finalName, // Use cached name if available, otherwise fallback to filename
                            country: finalCountry,
                            timestamp: new Date(
                                file.metadata.creationTime / 1000,
                            ).toISOString(),
                            image: "", // Will be populated later for photos that need thumbnails
                            fileId: file.id,
                        });
                        // Photo has no GPS data
                    }
                } catch {
                    // Silently ignore processing errors for individual files
                }
            }

            // Sort by timestamp
            photoData.sort(
                (a, b) =>
                    new Date(a.timestamp).getTime() -
                    new Date(b.timestamp).getTime(),
            );

            // Set journey data (location names will be fetched later)
            setJourneyData(photoData);

            // Mark initial load as complete
            setIsInitialLoad(false);

            // Set loading locations to true since we'll start fetching them
            if (photoData.length > 0) {
                setIsLoadingLocations(true);
            }
        };

        loadPhotosData();
    }, [files, journeyData.length]);

    // Load high quality cover image after initial data loads
    useEffect(() => {
        const loadCoverImage = async () => {
            if (journeyData.length === 0) return;

            let coverFile: EnteFile | undefined;

            // Check if there's a designated cover image in collection metadata
            const coverID = collection?.pubMagicMetadata?.data.coverID;
            if (coverID) {
                coverFile = files.find((f) => f.id === coverID);
            }

            // Fall back to first chronological photo if no cover is designated
            if (!coverFile) {
                const firstPhoto = journeyData[0];
                if (!firstPhoto) return;
                coverFile = files.find((f) => f.id === firstPhoto.fileId);
            }

            if (!coverFile) return;

            try {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(coverFile);
                if (sourceURLs.type === "image") {
                    setCoverImageUrl(sourceURLs.imageURL);
                }
            } catch {
                // Keep using thumbnail if high quality fails
            }
        };

        void loadCoverImage();
    }, [journeyData, files, collection]);

    // Fetch location names for clusters after they're created
    useEffect(() => {
        const fetchLocationNames = async () => {
            if (photoClusters.length === 0 || journeyData.length === 0) return;

            setIsLoadingLocations(true);

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
                        // Also cache it in the ref for persistence
                        locationDataRef.current.set(photo.fileId, {
                            name: locationInfo.place,
                            country: locationInfo.country,
                        });
                    });
                } catch {
                    // Silently ignore processing errors for individual files
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
        };

        void fetchLocationNames().catch(() => {
            setIsLoadingLocations(false);
        });
        // Only run when photoClusters changes, not journeyData to avoid infinite loop
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [photoClusters.length]);

    // Generate thumbnails only for photos that are actually used after clustering
    useEffect(() => {
        const generateNeededThumbnails = async () => {
            if (photoClusters.length === 0 || journeyData.length === 0) return;

            // Check if thumbnails have already been generated
            if (thumbnailsGeneratedRef.current) return;

            // Collect file IDs that need thumbnails
            const neededFileIds = new Set<number>();

            // First 3 photos of each cluster (covers map markers, super clusters, and timeline photo fans)
            photoClusters.forEach((cluster) => {
                cluster.slice(0, 3).forEach((photo) => {
                    neededFileIds.add(photo.fileId);
                });
            });

            // Find the files that need thumbnails
            const filesToProcess = files.filter((file) =>
                neededFileIds.has(file.id),
            );

            // Generate thumbnails and update journey data while preserving location names
            const thumbnailUpdates = new Map<number, string>();

            for (const file of filesToProcess) {
                try {
                    const thumbnailUrl =
                        await downloadManager.renderableThumbnailURL(file);
                    if (thumbnailUrl) {
                        thumbnailUpdates.set(file.id, thumbnailUrl);
                    }
                } catch {
                    // Silently ignore thumbnail generation errors
                }
            }

            // Update journey data by preserving all existing data and only updating images
            if (thumbnailUpdates.size > 0) {
                setJourneyData((prevData) =>
                    prevData.map((photo) => {
                        const thumbnailUrl = thumbnailUpdates.get(photo.fileId);
                        if (thumbnailUrl && !photo.image) {
                            return { ...photo, image: thumbnailUrl };
                        }
                        return photo;
                    }),
                );
            }
            thumbnailsGeneratedRef.current = true;
        };

        void generateNeededThumbnails().catch(() => {
            // Silently ignore thumbnail generation errors
        });
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

        // Use startTransition for lower-priority layout updates
        startTransition(() => {
            setLocationPositions(positions);
        });
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
        // Use startTransition for lower-priority scroll progress updates
        startTransition(() => {
            setScrollProgress(clampedProgress);
        });

        // Real-time map center update based on scroll progress
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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
                const firstCenter = clusterCenters[0];
                const lastCenter = clusterCenters[clusterCenters.length - 1];
                if (!firstCenter || !lastCenter) return;

                if (clampedProgress <= 0) {
                    // At the start, focus on first cluster
                    targetLat = firstCenter.lat;
                    targetLng = firstCenter.lng;
                } else if (clampedProgress === 1) {
                    // At the end, focus on last cluster
                    targetLat = lastCenter.lat;
                    targetLng = lastCenter.lng;
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
        return undefined;
    }, [photoClusters, updateLocationPositions]);

    // Throttled scroll handler for better performance
    const throttledTimelineScroll = useMemo(
        () => throttle(handleTimelineScroll, 16), // ~60fps
        [handleTimelineScroll],
    );

    // Add scroll event listener to timeline with throttling
    useEffect(() => {
        const timelineContainer = timelineRef.current;
        if (!timelineContainer) return;

        timelineContainer.addEventListener("scroll", throttledTimelineScroll);

        return () => {
            timelineContainer.removeEventListener(
                "scroll",
                throttledTimelineScroll,
            );
        };
    }, [throttledTimelineScroll, handleTimelineScroll]);

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

    // Shared marker click handler to avoid duplication
    const handleMarkerClick = useCallback(
        (clusterIndex: number, clusterLat: number, clusterLng: number) => {
            // Calculate target progress for immediate update
            const targetProgress =
                clusterIndex / Math.max(1, photoClusters.length - 1);

            // Clear any existing timeout
            if (clusterClickTimeoutRef.current) {
                clearTimeout(clusterClickTimeoutRef.current);
            }

            // Block scroll handler during cluster click
            isClusterClickScrollingRef.current = true;

            // Immediately update scroll progress to show green state
            setScrollProgress(targetProgress);

            // Calculate positioning offset for timeline visibility
            const allClusterLngs = photoClusters.map(
                (cluster) =>
                    cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length,
            );
            const minLng = Math.min(...allClusterLngs);
            const maxLng = Math.max(...allClusterLngs);
            const lngSpan = maxLng - minLng;
            const paddedSpan = Math.max(lngSpan * 1.4, 0.1);

            const isMobile = screenDimensions.width < 768;
            const timelineSizeRatio = isMobile ? 0.5 : 0.5;
            const mapSizeRatio = 1 - timelineSizeRatio;
            const screenWidthInDegrees = paddedSpan / mapSizeRatio;
            const shiftAmount = screenWidthInDegrees * (timelineSizeRatio / 2);
            const offsetLng = clusterLng - shiftAmount;

            if (mapRef) {
                const currentZoom = mapRef.getZoom();
                if (currentZoom > optimalZoom) {
                    mapRef.flyTo([clusterLat, offsetLng], optimalZoom, {
                        animate: true,
                        duration: 1.2,
                        easeLinearity: 0.25,
                    });
                } else {
                    mapRef.panTo([clusterLat, offsetLng], {
                        animate: true,
                        duration: 1.0,
                    });
                }
            }

            // Start timeline scrolling and set timeout to re-enable handler
            setTimeout(() => {
                scrollTimelineToLocation(clusterIndex);
            }, 50);

            // Re-enable scroll handler after animation completes
            clusterClickTimeoutRef.current = setTimeout(() => {
                isClusterClickScrollingRef.current = false;
                clusterClickTimeoutRef.current = null;
            }, 1500);
        },
        [
            photoClusters,
            screenDimensions,
            mapRef,
            optimalZoom,
            scrollTimelineToLocation,
        ],
    );

    // Only wait for client-side rendering (needed for maps), but show layout immediately
    // Let individual components handle their own loading states
    if (!isClient) {
        return null; // SSR compatibility
    }

    // Show black background if no photo data yet
    const hasPhotoData = journeyData.length > 0;

    return (
        <div style={{ position: "relative", width: "100%", height: "100%" }}>
            <TopNavButtons
                onAddPhotos={onAddPhotos}
                downloadAllFiles={downloadAllFiles}
                enableDownload={enableDownload}
            />
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
                    borderRadius: "48px",
                }}
            >
                <div style={{ padding: "32px" }}>
                    {isInitialLoad ? (
                        // Show loading cover placeholder
                        <div style={{ marginBottom: "96px" }}>
                            <div
                                style={{
                                    aspectRatio: "16/8",
                                    position: "relative",
                                    marginBottom: "12px",
                                    borderRadius: "24px",
                                    overflow: "hidden",
                                    backgroundColor: "#f3f4f6",
                                    animation:
                                        "pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite",
                                }}
                            >
                                <div
                                    style={{
                                        position: "absolute",
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: "128px",
                                        background:
                                            "linear-gradient(to top, rgba(0,0,0,0.3), transparent)",
                                    }}
                                ></div>
                                <div
                                    style={{
                                        position: "absolute",
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        padding: "24px",
                                        color: "rgba(255, 255, 255, 0.7)",
                                    }}
                                >
                                    <div
                                        style={{
                                            height: "30px",
                                            width: "200px",
                                            backgroundColor:
                                                "rgba(255, 255, 255, 0.2)",
                                            borderRadius: "4px",
                                            marginBottom: "2px",
                                        }}
                                    ></div>
                                    <div
                                        style={{
                                            height: "16px",
                                            width: "120px",
                                            backgroundColor:
                                                "rgba(255, 255, 255, 0.2)",
                                            borderRadius: "4px",
                                            margin: "0",
                                        }}
                                    ></div>
                                </div>
                            </div>
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
                                        animation: "spin 1s linear infinite",
                                        borderRadius: "50%",
                                        height: "40px",
                                        width: "40px",
                                        borderTop: "3px solid #10b981",
                                        borderRight: "3px solid transparent",
                                        borderBottom: "3px solid #10b981",
                                        borderLeft: "3px solid transparent",
                                    }}
                                ></div>
                            </div>
                        </div>
                    ) : journeyData.length > 0 ? (
                        <div>
                            <TripCover
                                journeyData={journeyData}
                                photoClusters={photoClusters}
                                albumTitle={collectionTitle}
                                coverImageUrl={coverImageUrl}
                            />

                            {/* Show either loading spinner or trip started section + timeline */}
                            {isLoadingLocations ? (
                                <div
                                    style={{
                                        position: "relative",
                                        marginTop: "64px",
                                        marginBottom: "200px",
                                        textAlign: "center",
                                        display: "flex",
                                        justifyContent: "center",
                                        alignItems: "center",
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
                                            borderBottom: "3px solid #10b981",
                                            borderLeft: "3px solid transparent",
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
                                            hasUserScrolled={hasUserScrolled}
                                            photoClusters={photoClusters}
                                        />

                                        {photoClusters.map((cluster, index) => (
                                            <TimelineLocation
                                                key={index}
                                                cluster={cluster}
                                                index={index}
                                                photoClusters={photoClusters}
                                                scrollProgress={scrollProgress}
                                                journeyData={journeyData}
                                                onRef={(el) => {
                                                    locationRefs.current[
                                                        index
                                                    ] = el;
                                                }}
                                                onPhotoClick={
                                                    handleOpenFileViewer
                                                }
                                            />
                                        ))}

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
            </div>

            {/* Map Container */}
            <TripMap
                journeyData={journeyData}
                photoClusters={photoClusters}
                hasPhotoData={hasPhotoData}
                optimalZoom={optimalZoom}
                currentZoom={currentZoom}
                targetZoom={targetZoom}
                mapRef={mapRef}
                scrollProgress={scrollProgress}
                screenDimensions={screenDimensions}
                setMapRef={setMapRef}
                setCurrentZoom={setCurrentZoom}
                setTargetZoom={setTargetZoom}
                onMarkerClick={handleMarkerClick}
            />

            {/* FileViewer for photo gallery */}
            <FileViewer
                open={openFileViewer}
                onClose={handleCloseFileViewer}
                initialIndex={currentFileIndex}
                files={viewerFiles}
                user={user}
                disableDownload={!enableDownload}
                onTriggerRemotePull={handleTriggerRemotePull}
                onRemoteFilesPull={handleTriggerRemotePull}
                onVisualFeedback={() => {
                    // No-op: Trip viewer is read-only and doesn't need visual feedback
                }}
            />

            {/* Download progress notifications */}
            <DownloadStatusNotifications
                saveGroups={saveGroups}
                onRemoveSaveGroup={onRemoveSaveGroup}
            />
        </div>
    );
};
