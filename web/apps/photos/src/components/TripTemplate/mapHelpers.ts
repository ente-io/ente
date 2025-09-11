import L from "leaflet";
import type { JourneyPoint } from "./types";
import { iconCache } from "./utils";

// Geographic clustering with responsive distance thresholds and day separation
export const clusterPhotosByProximity = (
    photos: JourneyPoint[],
    screenDimensions: { width: number; height: number },
) => {
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

// Calculate optimal zoom level based on cluster spread
export const calculateOptimalZoom = (
    photoClusters: JourneyPoint[][],
    screenDimensions: { width: number; height: number },
): number => {
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
    const visibleMapWidth = screenDimensions.width * (1 - timelineSizeRatio);

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
    const pixelsPerDegreeAtOptimalZoom = targetPixelSeparation / minDistance;
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
};

// Function to create icon with specific image and progress styling
export const createIcon = (
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
};

// Function to create super-cluster icon with badge
export const createSuperClusterIcon = (
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
};

// Calculate super-clusters based on screen collisions
export const detectScreenCollisions = (
    clusters: JourneyPoint[][],
    zoom: number,
    targetZoom: number | null,
    mapRef: L.Map | null,
    optimalZoom: number,
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
                totalLat += c.reduce((sum, p) => sum + p.lat, 0) / c.length;
                totalLng += c.reduce((sum, p) => sum + p.lng, 0) / c.length;
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

// Calculate map center - start at first location to match timeline initial state
export const getMapCenter = (
    photoClusters: JourneyPoint[][],
    journeyData: JourneyPoint[],
    screenDimensions: { width: number; height: number },
): [number, number] => {
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
        firstCluster.reduce((sum, p) => sum + p.lat, 0) / firstCluster.length;
    const firstLng =
        firstCluster.reduce((sum, p) => sum + p.lng, 0) / firstCluster.length;

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