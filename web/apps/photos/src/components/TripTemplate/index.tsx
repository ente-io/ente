import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import ShareIcon from "@mui/icons-material/Share";
import { DownloadStatusNotifications } from "components/DownloadStatusNotifications";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import { useSaveGroups } from "ente-gallery/components/utils/save-groups";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { downloadManager } from "ente-gallery/services/download";
import { downloadAndSaveCollectionFiles } from "ente-gallery/services/save";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { t } from "i18next";
import L from "leaflet";
import dynamic from "next/dynamic";
import {
    startTransition,
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";

// Import extracted components
import { TripCover } from "./TripCover";
import { TripStartedSection } from "./TripStartedSection";
import { TimelineProgressLine } from "./TimelineProgressLine";
import { TimelineBaseLine } from "./TimelineBaseLine";
import { TimelineLocation } from "./TimelineLocation";
import { MapEvents } from "./MapEvents";

// Import types and utils
import type { JourneyPoint } from "./types";
import { getLocationName, iconCache, throttle } from "./utils";

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

    // Check if device is touchscreen for signup button text
    const isTouchscreen = useIsTouchscreen();

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
    const locationDataRef = useRef<Map<number, { name: string; country: string }>>(new Map()); // Track location data to prevent resets
    const filesCountRef = useRef<number>(0); // Track files count to detect real changes

    // FileViewer state
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentFileIndex, setCurrentFileIndex] = useState(0);
    const [viewerFiles, setViewerFiles] = useState<EnteFile[]>([]); // Files to show in viewer
    const [showCopiedMessage, setShowCopiedMessage] = useState(false);

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
                // Batch state updates to avoid multiple re-renders
                setViewerFiles(sortedFiles);
                setCurrentFileIndex(clickedIndex);
                setOpenFileViewer(true);
                onSetOpenFileViewer?.(true);
            }
        },
        [files, onSetOpenFileViewer],
    );

    const handleCloseFileViewer = useCallback(() => {
        // Batch state updates
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

        // Find the bounding box of all clusters (only need lng values for calculations)
        const allLats = clusterCenters.map((c) => c.lat);
        const allLngs = clusterCenters.map((c) => c.lng);

        // Calculate the span (not used directly but kept for potential future use)
        // const latSpan = maxLat - minLat;
        // const lngSpan = maxLng - minLng;

        // Calculate minimum distances between clusters to avoid over-clustering
        let minDistance = Infinity;
        for (let i = 0; i < clusterCenters.length - 1; i++) {
            for (let j = i + 1; j < clusterCenters.length; j++) {
                const centerI = clusterCenters[i];
                const centerJ = clusterCenters[j];
                if (!centerI || !centerJ) continue;
                const distance = Math.sqrt(
                    Math.pow(centerI.lat - centerJ.lat, 2) +
                        Math.pow(centerI.lng - centerJ.lng, 2),
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
        const p10Lng = sortedClusterLngs[p10Index];
        const p90Lng = sortedClusterLngs[p90Index];
        const p10Lat = sortedClusterLats[p10Index];
        const p90Lat = sortedClusterLats[p90Index];
        if (
            p10Lng === undefined ||
            p90Lng === undefined ||
            p10Lat === undefined ||
            p90Lat === undefined
        ) {
            return 7; // fallback zoom
        }
        const effectiveLngSpan = p90Lng - p10Lng;
        const effectiveLatSpan = p90Lat - p10Lat;

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

        return Math.round(clampedZoom);
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
                        const cachedLocation = locationDataRef.current.get(file.id);
                        const finalName = cachedLocation?.name || fileFileName(file);
                        const finalCountry = cachedLocation?.country || "Unknown";
                        
                        
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
            photoClusters.forEach(cluster => {
                cluster.slice(0, 3).forEach(photo => {
                    neededFileIds.add(photo.fileId);
                });
            });

            // Find the files that need thumbnails
            const filesToProcess = files.filter(file => 
                neededFileIds.has(file.id)
            );

            // Generate thumbnails and update journey data while preserving location names
            const thumbnailUpdates = new Map<number, string>();
            
            for (const file of filesToProcess) {
                try {
                    const thumbnailUrl = await downloadManager.renderableThumbnailURL(file);
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

    // Function to create icon with specific image and progress styling
    const createIcon = useCallback(
        (
            imageSrc: string,
            size = 40,
            borderColor = "#ffffff",
            _clusterCount?: number,
            isReached = false,
        ): L.DivIcon => {
            if (typeof window === "undefined") {
                // Fallback icon for SSR
                return L.divIcon({ html: "", className: "empty-marker" });
            }

            // Create cache key based on all parameters
            const cacheKey = `icon_${imageSrc}_${size}_${borderColor}_${isReached}`;

            const cachedIcon = iconCache.get(cacheKey);
            if (cachedIcon) {
                return cachedIcon;
            }

            const pinSize = size + 16; // Make it square and bigger
            const pinHeight = pinSize + 12; // Add space for triangle
            const triangleHeight = 10;

            // L is imported at the top of the file
            const icon = L.divIcon({
                html: `
        <div class="photo-pin${isReached ? " reached" : ""}" style="
          width: ${pinSize}px;
          height: ${pinHeight}px;
          position: relative;
          cursor: pointer;
          transition: all 0.3s ease;
        ">
          <!-- Main rounded rectangle container -->
          <div style="
            width: ${pinSize}px;
            height: ${pinSize}px;
            border-radius: 16px;
            background: ${isReached ? "#22c55e" : "white"};
            border: 2px solid ${isReached ? "#22c55e" : borderColor};
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
            padding: 4px;
            position: relative;
            overflow: hidden;
            transition: background-color 0.3s ease, border-color 0.3s ease;
          "
          onmouseover="this.style.background='#22c55e'; this.style.borderColor='#22c55e'; this.nextElementSibling.style.borderTopColor='#22c55e';"
          onmouseout="this.style.background='${isReached ? "#22c55e" : "white"}'; this.style.borderColor='${isReached ? "#22c55e" : "#ffffff"}'; this.nextElementSibling.style.borderTopColor='${isReached ? "#22c55e" : "white"}';"
          >
            <!-- Image inside the rounded rectangle -->
            <img 
              src="${imageSrc}" 
              style="
                width: 100%;
                height: 100%;
                object-fit: cover;
                border-radius: 12px;
              "
              alt="Location"
            />
          </div>
          
          <!-- Triangle at the bottom -->
          <div style="
            position: absolute;
            bottom: 2px;
            left: 50%;
            transform: translateX(-50%);
            width: 0;
            height: 0;
            border-left: ${triangleHeight}px solid transparent;
            border-right: ${triangleHeight}px solid transparent;
            border-top: ${triangleHeight}px solid ${isReached ? "#22c55e" : "white"};
            filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
            transition: border-top-color 0.3s ease;
          "></div>
        </div>
      `,
                className: "custom-pin-marker",
                iconSize: [pinSize, pinHeight],
                iconAnchor: [pinSize / 2, pinHeight],
                popupAnchor: [0, -pinHeight],
            });

            // Cache the icon
            iconCache.set(cacheKey, icon);
            return icon;
        },
        [],
    );

    // Function to create super-cluster icon with badge
    const createSuperClusterIcon = useCallback(
        (
            imageSrc: string,
            clusterCount: number,
            size = 45,
            isReached = false,
        ): L.DivIcon => {
            if (typeof window === "undefined") {
                // Fallback icon for SSR
                return L.divIcon({ html: "", className: "empty-marker" });
            }

            // Create cache key based on all parameters
            const cacheKey = `super_icon_${imageSrc}_${clusterCount}_${size}_${isReached}`;

            const cachedIcon = iconCache.get(cacheKey);
            if (cachedIcon) {
                return cachedIcon;
            }

            const pinSize = size + 16; // Make it square and bigger
            const pinHeight = pinSize + 12; // Add space for triangle
            const triangleHeight = 10;
            const containerSize = pinSize + 24;

            const icon = L.divIcon({
                html: `
        <div class="super-cluster-container" style="
          width: ${containerSize}px;
          height: ${pinHeight + 12}px;
          position: relative;
          cursor: pointer;
        ">
          <!-- Main pin container -->
          <div class="photo-pin${isReached ? " reached" : ""}" style="
            width: ${pinSize}px;
            height: ${pinHeight}px;
            position: absolute;
            left: 12px;
            top: 0;
            transition: all 0.3s ease;
          ">
            <!-- Main rounded rectangle container -->
            <div style="
              width: ${pinSize}px;
              height: ${pinSize}px;
              border-radius: 16px;
              background: ${isReached ? "#22c55e" : "white"};
              border: 2px solid ${isReached ? "#22c55e" : "#ffffff"};
              box-shadow: 0 4px 8px rgba(0,0,0,0.3);
              padding: 4px;
              position: relative;
              overflow: hidden;
              transition: background-color 0.3s ease, border-color 0.3s ease;
            "
            onmouseover="this.style.background='#22c55e'; this.style.borderColor='#22c55e'; this.nextElementSibling.style.borderTopColor='#22c55e';"
            onmouseout="this.style.background='${isReached ? "#22c55e" : "white"}'; this.style.borderColor='${isReached ? "#22c55e" : "#ffffff"}'; this.nextElementSibling.style.borderTopColor='${isReached ? "#22c55e" : "white"}';"
            >
              <!-- Image inside the rounded rectangle -->
              <img 
                src="${imageSrc}" 
                style="
                  width: 100%;
                  height: 100%;
                  object-fit: cover;
                  border-radius: 12px;
                "
                alt="Location"
              />
            </div>
            
            <!-- Triangle at the bottom -->
            <div style="
              position: absolute;
              bottom: 2px;
              left: 50%;
              transform: translateX(-50%);
              width: 0;
              height: 0;
              border-left: ${triangleHeight}px solid transparent;
              border-right: ${triangleHeight}px solid transparent;
              border-top: ${triangleHeight}px solid ${isReached ? "#22c55e" : "white"};
              filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
              transition: border-top-color 0.3s ease;
            "></div>
          </div>
          
          <!-- Badge -->
          <div style="
            position: absolute;
            top: -6px;
            right: 0;
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
            border: 2px solid white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
            z-index: 10;
          ">${clusterCount}</div>
        </div>
      `,
                className: "super-cluster-pin-marker",
                iconSize: [containerSize, pinHeight + 12],
                iconAnchor: [containerSize / 2, pinHeight + 12],
                popupAnchor: [0, -(pinHeight + 12)],
            });

            // Cache the icon
            iconCache.set(cacheKey, icon);
            return icon;
        },
        [],
    );

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
                        if (!c) return;
                        totalLat +=
                            c.reduce((sum, p) => sum + p.lat, 0) / c.length;
                        totalLng +=
                            c.reduce((sum, p) => sum + p.lng, 0) / c.length;
                    });

                    // Get the first photo from the first cluster as representative image
                    const firstClusterIdx = overlappingClusters[0];
                    const firstCluster =
                        firstClusterIdx !== undefined
                            ? clusters[firstClusterIdx]
                            : undefined;
                    const representativePhoto = firstCluster?.[0];
                    if (!representativePhoto) {
                        return;
                    }

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
            {/* Top right buttons - Fixed to viewport */}
            <div
                style={{
                    position: "fixed",
                    top: "20px",
                    right: "20px",
                    display: "flex",
                    gap: "8px",
                    zIndex: 2000,
                }}
            >
                {onAddPhotos && (
                    <button
                        onClick={onAddPhotos}
                        style={{
                            padding: "12px",
                            backgroundColor: "rgba(255, 255, 255, 0.9)",
                            border: "none",
                            borderRadius: "8px",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            color: "#1f2937",
                            transition: "background-color 0.2s",
                            backdropFilter: "blur(10px)",
                            boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
                            width: "44px",
                            height: "44px",
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor =
                                "rgba(255, 255, 255, 1)";
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor =
                                "rgba(255, 255, 255, 0.9)";
                        }}
                    >
                        <AddPhotoAlternateOutlinedIcon
                            style={{ fontSize: "22px" }}
                        />
                    </button>
                )}
                <button
                    onClick={() => {
                        if (typeof window !== "undefined") {
                            void navigator.clipboard.writeText(
                                window.location.href,
                            );
                            setShowCopiedMessage(true);
                            setTimeout(() => setShowCopiedMessage(false), 2000);
                        }
                    }}
                    style={{
                        padding: "12px",
                        backgroundColor: "rgba(255, 255, 255, 0.9)",
                        border: "none",
                        borderRadius: "8px",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "#1f2937",
                        transition: "background-color 0.2s",
                        backdropFilter: "blur(10px)",
                        boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
                        width: "44px",
                        height: "44px",
                    }}
                    onMouseEnter={(e) => {
                        e.currentTarget.style.backgroundColor =
                            "rgba(255, 255, 255, 1)";
                    }}
                    onMouseLeave={(e) => {
                        e.currentTarget.style.backgroundColor =
                            "rgba(255, 255, 255, 0.9)";
                    }}
                >
                    <ShareIcon style={{ fontSize: "20px" }} />
                </button>
                {!enableDownload && (
                    <button
                        onClick={downloadAllFiles}
                        style={{
                            padding: "12px",
                            backgroundColor: "rgba(255, 255, 255, 0.9)",
                            border: "none",
                            borderRadius: "8px",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            color: "#1f2937",
                            transition: "background-color 0.2s",
                            backdropFilter: "blur(10px)",
                            boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
                            width: "44px",
                            height: "44px",
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor =
                                "rgba(255, 255, 255, 1)";
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor =
                                "rgba(255, 255, 255, 0.9)";
                        }}
                    >
                        <FileDownloadOutlinedIcon
                            style={{ fontSize: "23px" }}
                        />
                    </button>
                )}
                <button
                    onClick={() => {
                        if (typeof window !== "undefined") {
                            window.open(
                                "https://ente.io",
                                "_blank",
                                "noopener,noreferrer",
                            );
                        }
                    }}
                    style={{
                        padding: "12px 16px",
                        marginLeft: "12px",
                        backgroundColor: "rgba(255, 255, 255, 0.9)",
                        border: "none",
                        borderRadius: "8px",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "#1f2937",
                        transition: "background-color 0.2s",
                        backdropFilter: "blur(10px)",
                        boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
                        fontSize: "16px",
                        fontWeight: "600",
                        whiteSpace: "nowrap",
                    }}
                    onMouseEnter={(e) => {
                        e.currentTarget.style.backgroundColor =
                            "rgba(255, 255, 255, 1)";
                    }}
                    onMouseLeave={(e) => {
                        e.currentTarget.style.backgroundColor =
                            "rgba(255, 255, 255, 0.9)";
                    }}
                >
                    {isTouchscreen ? t("install") : t("sign_up")}
                </button>
            </div>

            {/* Copied message */}
            {showCopiedMessage && (
                <div
                    style={{
                        position: "fixed",
                        top: "80px",
                        right: "20px",
                        backgroundColor: "#22c55e",
                        color: "white",
                        padding: "8px 16px",
                        borderRadius: "8px",
                        fontSize: "14px",
                        fontWeight: "500",
                        zIndex: 2001,
                        boxShadow: "0 4px 12px rgba(0, 0, 0, 0.2)",
                        animation: "fadeInOut 2s ease-in-out forwards",
                    }}
                >
                    Copied!
                </div>
            )}
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
                                    (clusterIdx) =>
                                        photoClusters[clusterIdx] || [],
                                );


                            // Check if this super-cluster has been reached
                            const firstClusterIndex =
                                superCluster.clustersInvolved[0];
                            const isReached =
                                firstClusterIndex !== undefined &&
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
                                        superCluster.image, // Use representative photo (first photo of first cluster)
                                        superCluster.clusterCount,
                                        55,
                                        isReached,
                                    )}
                                    eventHandlers={{
                                        click: () => {
                                            const firstClusterIndex =
                                                superCluster
                                                    .clustersInvolved[0];
                                            if (
                                                firstClusterIndex !== undefined
                                            ) {
                                                handleMarkerClick(
                                                    firstClusterIndex,
                                                    superCluster.lat,
                                                    superCluster.lng,
                                                );
                                            }
                                        },
                                    }}
                                />
                            );
                        })}

                        {/* Draw visible regular clusters */}
                        {visibleClusters.map((cluster, index) => {
                            const firstPhoto = cluster[0];
                            if (!firstPhoto) return null;
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
                                        originalCluster[0]?.image ===
                                            cluster[0]?.image,
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
                                        55,
                                        "#ffffff",
                                        cluster.length,
                                        isReached,
                                    )}
                                    eventHandlers={{
                                        click: () => {
                                            // Calculate cluster center
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
                                            handleMarkerClick(
                                                originalClusterIndex,
                                                avgLat,
                                                avgLng,
                                            );
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