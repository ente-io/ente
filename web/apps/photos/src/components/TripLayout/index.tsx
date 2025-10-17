import { Box, styled, useMediaQuery, useTheme } from "@mui/material";
import { DownloadStatusNotifications } from "components/DownloadStatusNotifications";
import { useSaveGroups } from "ente-gallery/components/utils/save-groups";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { downloadAndSaveCollectionFiles } from "ente-gallery/services/save";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { useEffect, useRef, useState } from "react";

// Import extracted components
import { MobileCover } from "./MobileCover";
import { MobileNavBar } from "./MobileNavBar";
import { MobileTimelineLocation } from "./MobileTimelineLocation";
import { MobileTripStarted } from "./MobileTripStarted";
import { TimelineBaseLine } from "./TimelineBaseLine";
import { TimelineLocation } from "./TimelineLocation";
import { TimelineProgressLine } from "./TimelineProgressLine";
import { TopNavButtons } from "./TopNavButtons";
import { TripCover } from "./TripCover";

// Import hooks
import { useDataProcessing } from "./hooks/useDataProcessing";
import { useFileViewer } from "./hooks/useFileViewer";
import { useLocationFetching } from "./hooks/useLocationFetching";
import { useScrollHandling } from "./hooks/useScrollHandling";
import { useThumbnailGeneration } from "./hooks/useThumbnailGeneration";

// Import types and utils
import type { JourneyPoint } from "./types";
import type { PositionInfo } from "./utils/scrollUtils";

interface TripLayoutProps {
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

export const TripLayout: React.FC<TripLayoutProps> = ({
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

    // Use media query for mobile/tablet detection (up to 960px)
    const theme = useTheme();
    const isMobileOrTablet = useMediaQuery(theme.breakpoints.down("md")); // 960px breakpoint for mobile and tablet

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

    const [journeyData, setJourneyData] = useState<JourneyPoint[]>([]);
    const [coverImageUrl, setCoverImageUrl] = useState<string | null>(null);
    const [isClient, setIsClient] = useState(false);
    const [isLoadingLocations, setIsLoadingLocations] = useState(false);
    const [isInitialLoad, setIsInitialLoad] = useState(true);
    const [currentZoom, setCurrentZoom] = useState(7); // Default zoom, will be updated by MapEvents and optimalZoom
    const [mapRef, setMapRef] = useState<import("leaflet").Map | null>(null);
    const [targetZoom, setTargetZoom] = useState<number | null>(null);
    const [scrollProgress, setScrollProgress] = useState(0); // 0 to 1 representing scroll progress
    const [hasUserScrolled, setHasUserScrolled] = useState(false); // Track if user has actually scrolled
    const [showMobileCover, setShowMobileCover] = useState(true); // Track mobile cover state
    const [locationPositions, setLocationPositions] = useState<PositionInfo[]>(
        [],
    );
    const timelineRef = useRef<HTMLDivElement>(null);
    const locationRefs = useRef<(HTMLDivElement | null)[]>([]);
    const tripStartedRef = useRef<HTMLDivElement | null>(null);
    const isClusterClickScrollingRef = useRef(false); // Use ref for immediate updates
    const clusterClickTimeoutRef = useRef<NodeJS.Timeout | null>(null); // Timeout for cluster clicks
    const thumbnailsGeneratedRef = useRef(false); // Track if thumbnails have been generated
    const locationDataRef = useRef<
        Map<number, { name: string; country: string }>
    >(new Map()); // Track location data to prevent resets
    const filesCountRef = useRef<number>(0); // Track files count to detect real changes
    const previousActiveLocationRef = useRef<number>(-1); // Track previous active location for discrete panning
    const previousSuperClusterStateRef = useRef<{
        isInSuperCluster: boolean;
        superClusterIndex: number | null;
    }>({ isInSuperCluster: false, superClusterIndex: null }); // Track previous super cluster state for zoom logic

    const [photoClusters, setPhotoClusters] = useState<JourneyPoint[][]>([]);
    const [optimalZoom, setOptimalZoom] = useState(7);
    const [superClusterInfo, setSuperClusterInfo] = useState<{
        superClusters: {
            lat: number;
            lng: number;
            clusterCount: number;
            clustersInvolved: number[];
            image: string;
        }[];
        clusterToSuperClusterMap: Map<number, number>;
    }>({ superClusters: [], clusterToSuperClusterMap: new Map() });
    const [TripMapComponent, setTripMapComponent] =
        useState<React.ComponentType<{
            journeyData: JourneyPoint[];
            photoClusters: JourneyPoint[][];
            hasPhotoData: boolean;
            optimalZoom: number;
            currentZoom: number;
            targetZoom: number | null;
            mapRef: import("leaflet").Map | null;
            scrollProgress: number;
            superClusterInfo?: {
                superClusters: {
                    lat: number;
                    lng: number;
                    clusterCount: number;
                    clustersInvolved: number[];
                    image: string;
                }[];
                clusterToSuperClusterMap: Map<number, number>;
            };
            setMapRef: (map: import("leaflet").Map | null) => void;
            setCurrentZoom: (zoom: number) => void;
            setTargetZoom: (zoom: number | null) => void;
            onMarkerClick: (
                clusterIndex: number,
                clusterLat: number,
                clusterLng: number,
            ) => void;
        }> | null>(null);

    // Load client-side components and calculations
    useEffect(() => {
        if (isClient) {
            // Load TripMap component
            void import("./TripMap").then(({ TripMap }) => {
                setTripMapComponent(() => TripMap);
            });

            // Load mapHelpers and calculate clusters if we have data
            if (journeyData.length > 0) {
                void import("./mapHelpers").then(
                    ({
                        clusterPhotosByProximity,
                        calculateOptimalZoom,
                        detectScreenCollisions,
                    }) => {
                        const clusters = clusterPhotosByProximity(journeyData);

                        // Sort clusters by their earliest timestamp to maintain chronological order
                        const sortedClusters = clusters.sort((a, b) => {
                            const earliestA = Math.min(
                                ...a.map((p) =>
                                    new Date(p.timestamp).getTime(),
                                ),
                            );
                            const earliestB = Math.min(
                                ...b.map((p) =>
                                    new Date(p.timestamp).getTime(),
                                ),
                            );
                            return earliestA - earliestB;
                        });

                        const optimalZoomLevel = calculateOptimalZoom();

                        // Calculate super clusters at optimal zoom level once
                        const { superClusters } = detectScreenCollisions(
                            sortedClusters,
                            optimalZoomLevel,
                            null,
                            null,
                            optimalZoomLevel,
                        );

                        // Create a map of cluster index to super cluster index
                        const clusterToSuperClusterMap = new Map<
                            number,
                            number
                        >();
                        superClusters.forEach(
                            (superCluster, superClusterIndex) => {
                                superCluster.clustersInvolved.forEach(
                                    (clusterIndex) => {
                                        clusterToSuperClusterMap.set(
                                            clusterIndex,
                                            superClusterIndex,
                                        );
                                    },
                                );
                            },
                        );

                        setPhotoClusters(sortedClusters);

                        // Check if first location is in a super cluster and adjust initial zoom
                        const firstLocationInSuperCluster =
                            clusterToSuperClusterMap.has(0);
                        const initialZoom = firstLocationInSuperCluster
                            ? isMobileOrTablet
                                ? 15
                                : 14 // Super cluster zoom level
                            : optimalZoomLevel;

                        setOptimalZoom(initialZoom);
                        setSuperClusterInfo({
                            superClusters,
                            clusterToSuperClusterMap,
                        });
                    },
                );
            }
        }
    }, [isClient, journeyData, isMobileOrTablet]);

    // Update currentZoom when optimalZoom changes and there's no mapRef yet
    useEffect(() => {
        if (!mapRef && optimalZoom !== currentZoom) {
            setCurrentZoom(optimalZoom);
        }
    }, [optimalZoom, mapRef, currentZoom]);

    // Set client-side rendering flag
    useEffect(() => {
        setIsClient(true);
    }, []);

    // Use extracted data processing hooks
    useDataProcessing({
        files,
        collection,
        journeyData,
        thumbnailsGeneratedRef,
        filesCountRef,
        locationDataRef,
        setJourneyData,
        setIsInitialLoad,
        setIsLoadingLocations,
        setCoverImageUrl,
    });

    useLocationFetching({
        photoClusters,
        journeyData,
        locationDataRef,
        setJourneyData,
        setIsLoadingLocations,
    });

    useThumbnailGeneration({
        photoClusters,
        journeyData,
        files,
        thumbnailsGeneratedRef,
        setJourneyData,
    });

    // Use extracted scroll handling hooks
    const { markerClickHandler } = useScrollHandling({
        timelineRef,
        photoClusters,
        locationPositions,
        mapRef,
        locationRefs,
        isClusterClickScrollingRef,
        clusterClickTimeoutRef,
        previousActiveLocationRef,
        setLocationPositions,
        isMobileOrTablet,
        setHasUserScrolled: (scrolled: boolean) => {
            setHasUserScrolled(scrolled);
            if (
                isMobileOrTablet &&
                tripStartedRef.current &&
                timelineRef.current
            ) {
                const timelineContainer = timelineRef.current;
                const tripStartedElement = tripStartedRef.current;
                const tripStartedRect =
                    tripStartedElement.getBoundingClientRect();
                const timelineRect = timelineContainer.getBoundingClientRect();

                // Show/hide cover based on trip started position
                const threshold = timelineRect.top + timelineRect.height * 0.3;
                if (tripStartedRect.bottom < threshold) {
                    setShowMobileCover(false);
                } else {
                    setShowMobileCover(true);
                }
            }
        },
        setScrollProgress,
        setTargetZoom,
        previousSuperClusterStateRef,
        superClusterInfo,
        scrollProgress,
    });

    // Only wait for client-side rendering (needed for maps), but show layout immediately
    // Let individual components handle their own loading states
    if (!isClient) {
        return null; // SSR compatibility
    }

    // Show black background if no photo data yet
    const hasPhotoData = journeyData.length > 0;

    return (
        <TripLayoutContainer>
            {!openFileViewer &&
                (isMobileOrTablet ? (
                    <MobileNavBar
                        onAddPhotos={onAddPhotos}
                        downloadAllFiles={downloadAllFiles}
                        enableDownload={enableDownload}
                        collectionTitle={collectionTitle}
                    />
                ) : (
                    <TopNavButtons
                        onAddPhotos={onAddPhotos}
                        downloadAllFiles={downloadAllFiles}
                        enableDownload={enableDownload}
                    />
                ))}
            {/* Mobile Layout */}
            {isMobileOrTablet ? (
                <MobileContainer>
                    {/* Map takes 60% of height */}
                    <MobileMapContainer>
                        {TripMapComponent && (
                            <TripMapComponent
                                journeyData={journeyData}
                                photoClusters={photoClusters}
                                hasPhotoData={hasPhotoData}
                                optimalZoom={optimalZoom}
                                currentZoom={currentZoom}
                                targetZoom={targetZoom}
                                mapRef={mapRef}
                                scrollProgress={scrollProgress}
                                superClusterInfo={superClusterInfo}
                                setMapRef={setMapRef}
                                setCurrentZoom={setCurrentZoom}
                                setTargetZoom={setTargetZoom}
                                onMarkerClick={markerClickHandler}
                            />
                        )}
                        {/* Cover overlay */}
                        {!isInitialLoad && journeyData.length > 0 && (
                            <MobileCoverOverlay show={showMobileCover}>
                                <MobileCover
                                    journeyData={journeyData}
                                    albumTitle={collectionTitle}
                                    coverImageUrl={coverImageUrl}
                                />
                            </MobileCoverOverlay>
                        )}
                    </MobileMapContainer>

                    {/* Timeline takes 40% of height */}
                    <MobileTimelineContainer ref={timelineRef}>
                        <MobileTimelineContent>
                            {isInitialLoad ? (
                                <MobileLoadingContainer>
                                    <LoadingSpinner />
                                </MobileLoadingContainer>
                            ) : journeyData.length > 0 ? (
                                <div>
                                    {isLoadingLocations ? (
                                        <LocationsLoadingContainer>
                                            <LoadingSpinner />
                                        </LocationsLoadingContainer>
                                    ) : (
                                        <>
                                            <MobileTripStarted
                                                onRef={(el) => {
                                                    tripStartedRef.current = el;
                                                }}
                                                journeyData={journeyData}
                                            />

                                            <TimelineContainer id="timeline-container">
                                                <MobileTimelineBaseLine
                                                    photoClusters={
                                                        photoClusters
                                                    }
                                                />

                                                {photoClusters.map(
                                                    (cluster, index) => (
                                                        <MobileTimelineLocation
                                                            key={index}
                                                            cluster={cluster}
                                                            index={index}
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
                                            </TimelineContainer>
                                        </>
                                    )}
                                </div>
                            ) : (
                                <NoPhotosContainer>
                                    No photos found with location information.
                                </NoPhotosContainer>
                            )}
                        </MobileTimelineContent>
                    </MobileTimelineContainer>
                </MobileContainer>
            ) : (
                <>
                    {/* Desktop Layout - Left Sidebar - Floating Timeline */}
                    <TimelineSidebar ref={timelineRef}>
                        <TimelineContent>
                            {isInitialLoad ? (
                                <LoadingCoverPlaceholder>
                                    <LoadingCoverImage>
                                        <CoverGradientOverlay />
                                        <CoverPlaceholderContent>
                                            <PlaceholderTextBox
                                                sx={{
                                                    height: "30px",
                                                    width: "200px",
                                                    mb: "2px",
                                                }}
                                            />
                                            <PlaceholderTextBox
                                                sx={{
                                                    height: "16px",
                                                    width: "120px",
                                                    margin: 0,
                                                }}
                                            />
                                        </CoverPlaceholderContent>
                                    </LoadingCoverImage>
                                    <LoadingSpinnerContainer>
                                        <LoadingSpinner />
                                    </LoadingSpinnerContainer>
                                </LoadingCoverPlaceholder>
                            ) : journeyData.length > 0 ? (
                                <div>
                                    <TripCover
                                        journeyData={journeyData}
                                        albumTitle={collectionTitle}
                                        coverImageUrl={coverImageUrl}
                                    />

                                    {isLoadingLocations ? (
                                        <LocationsLoadingContainer>
                                            <LoadingSpinner />
                                        </LocationsLoadingContainer>
                                    ) : (
                                        <>
                                            <TimelineContainer id="timeline-container">
                                                <TimelineBaseLine
                                                    locationPositions={
                                                        locationPositions
                                                    }
                                                />

                                                <TimelineProgressLine
                                                    locationPositions={
                                                        locationPositions
                                                    }
                                                    scrollProgress={
                                                        scrollProgress
                                                    }
                                                    hasUserScrolled={
                                                        hasUserScrolled
                                                    }
                                                    photoClusters={
                                                        photoClusters
                                                    }
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
                                            </TimelineContainer>
                                        </>
                                    )}
                                </div>
                            ) : (
                                <NoPhotosContainer>
                                    No photos found with location information.
                                </NoPhotosContainer>
                            )}
                        </TimelineContent>
                    </TimelineSidebar>

                    {/* Desktop Map Container */}
                    {TripMapComponent && (
                        <TripMapComponent
                            journeyData={journeyData}
                            photoClusters={photoClusters}
                            hasPhotoData={hasPhotoData}
                            optimalZoom={optimalZoom}
                            currentZoom={currentZoom}
                            targetZoom={targetZoom}
                            mapRef={mapRef}
                            scrollProgress={scrollProgress}
                            superClusterInfo={superClusterInfo}
                            setMapRef={setMapRef}
                            setCurrentZoom={setCurrentZoom}
                            setTargetZoom={setTargetZoom}
                            onMarkerClick={markerClickHandler}
                        />
                    )}
                </>
            )}

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
        </TripLayoutContainer>
    );
};

// Styled components
const TripLayoutContainer = styled(Box)({
    position: "relative",
    width: "100%",
    height: "100%",
});

const TimelineSidebar = styled(Box)(({ theme }) => ({
    position: "absolute",
    left: "16px",
    top: "16px",
    bottom: "16px",
    width: "680px",
    overflow: "auto",
    boxShadow: theme.shadows[10],
    backgroundColor: theme.palette.background.paper,
    zIndex: 1000,
    borderRadius: "48px",
    "&::-webkit-scrollbar": { width: "8px" },
    "&::-webkit-scrollbar-track": {
        background: "transparent",
        borderRadius: "48px",
    },
    "&::-webkit-scrollbar-thumb": {
        background: theme.palette.divider,
        borderRadius: "48px",
        "&:hover": { background: theme.palette.text.disabled },
    },
    scrollbarWidth: "thin",
    scrollbarColor: `${theme.palette.divider} transparent`,
    [theme.breakpoints.up(1600)]: { width: "960px" },
}));

const TimelineContent = styled(Box)({
    padding: "32px",
    height: "100%",
    display: "flex",
    flexDirection: "column",
});

const LoadingCoverPlaceholder = styled(Box)({ marginBottom: "96px" });

const LoadingCoverImage = styled(Box)(({ theme }) => ({
    aspectRatio: "16/8",
    position: "relative",
    marginBottom: "12px",
    borderRadius: "24px",
    overflow: "hidden",
    backgroundColor: theme.palette.grey[200],
    animation: "pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite",
    "@keyframes pulse": { "0%, 100%": { opacity: 1 }, "50%": { opacity: 0.5 } },
}));

const CoverGradientOverlay = styled(Box)({
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: "128px",
    background: "linear-gradient(to top, rgba(0,0,0,0.3), transparent)",
});

const CoverPlaceholderContent = styled(Box)({
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    padding: "24px",
    color: "rgba(255, 255, 255, 0.7)",
});

const PlaceholderTextBox = styled(Box)({
    backgroundColor: "rgba(255, 255, 255, 0.2)",
    borderRadius: "4px",
});

const LoadingSpinnerContainer = styled(Box)({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "60px 20px",
    minHeight: "200px",
});

const LoadingSpinner = styled(Box)(({ theme }) => ({
    animation: "spin 1s linear infinite",
    borderRadius: "50%",
    height: "40px",
    width: "40px",
    borderTop: `3px solid ${theme.palette.success.main}`,
    borderRight: "3px solid transparent",
    borderBottom: `3px solid ${theme.palette.success.main}`,
    borderLeft: "3px solid transparent",
    "@keyframes spin": {
        from: { transform: "rotate(0deg)" },
        to: { transform: "rotate(360deg)" },
    },
}));

const LocationsLoadingContainer = styled(Box)({
    position: "relative",
    marginTop: "64px",
    marginBottom: "200px",
    textAlign: "center",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
});

const TimelineContainer = styled(Box)({ position: "relative" });

const NoPhotosContainer = styled(Box)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    textAlign: "center",
    width: "100%",
    flex: 1,
    padding: "40px 20px",
    color: theme.palette.text.secondary,
    fontSize: "16px",
}));

// Mobile specific styled components
const MobileContainer = styled(Box)({
    display: "flex",
    flexDirection: "column",
    height: "100svh",
    width: "100%",
});

const MobileMapContainer = styled(Box)({
    height: "calc(60svh + 20px)",
    position: "relative",
    overflow: "hidden",
});

const MobileTimelineContainer = styled(Box)(({ theme }) => ({
    height: "40svh",
    marginTop: "-20px",
    overflow: "auto",
    backgroundColor: theme.palette.background.paper,
    boxShadow: `0 -4px 20px rgba(0, 0, 0, 0.1)`,
    scrollSnapType: "y mandatory",
    borderTopLeftRadius: "24px",
    borderTopRightRadius: "24px",
    zIndex: 1001,
    "&::-webkit-scrollbar": { width: "6px" },
    "&::-webkit-scrollbar-track": { background: "transparent" },
    "&::-webkit-scrollbar-thumb": {
        background: theme.palette.divider,
        borderRadius: "20px",
        "&:hover": { background: theme.palette.text.disabled },
    },
    scrollbarWidth: "thin",
    scrollbarColor: `${theme.palette.divider} transparent`,
}));

const MobileCoverOverlay = styled(Box, {
    shouldForwardProp: (prop) => prop !== "show",
})<{ show: boolean }>(({ show }) => ({
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1000,
    opacity: show ? 1 : 0,
    transition: "opacity 0.5s ease-in-out",
    pointerEvents: show ? "auto" : "none",
}));

const MobileTimelineContent = styled(Box)({
    padding: "0",
    height: "100%",
    display: "flex",
    flexDirection: "column",
});

const MobileLoadingContainer = styled(Box)({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    height: "100%",
    width: "100%",
});

const MobileTimelineBaseLine = styled(Box, {
    shouldForwardProp: (prop) => prop !== "photoClusters",
})<{ photoClusters: JourneyPoint[][] }>(({ theme, photoClusters }) => ({
    position: "absolute",
    left: "50%",
    top: "-15svh",
    height: `${(photoClusters.length - 1) * 40 + 35}svh`,
    width: "3px",
    backgroundColor: theme.palette.grey[300],
    transform: "translateX(-1.5px)",
    zIndex: 0,
}));
