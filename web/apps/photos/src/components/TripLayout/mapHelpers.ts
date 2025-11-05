import { haveWindow } from "ente-base/env";
import type { JourneyPoint } from "./types";
import { iconCache } from "./utils/geocoding";

// Mobile/tablet detection using media query breakpoint
const isMobileDevice = () => {
    if (typeof window === "undefined") return false;
    // Use 960px breakpoint to match Material-UI's "md" breakpoint for mobile and tablet
    return window.innerWidth < 960;
};

// Conditionally import leaflet only in browser environment
const getLeaflet = () => {
    if (haveWindow()) {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        return require("leaflet") as typeof import("leaflet");
    }
    return null;
};

// Calculate distance between two points using Haversine formula (returns distance in km)
export const calculateDistance = (
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number,
): number => {
    const R = 6371; // Radius of Earth in kilometers
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLng = (lng2 - lng1) * (Math.PI / 180);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) *
            Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

// Geographic clustering with responsive distance thresholds and day separation
export const clusterPhotosByProximity = (photos: JourneyPoint[]) => {
    if (photos.length === 0) return [];

    // 25km clustering distance (roughly 0.25 degrees)
    const distanceThreshold = 0.25; // About 25km in degrees

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

// Return fixed zoom level of 10 for consistent positioning
export const calculateOptimalZoom = (): number => {
    // Return fixed zoom of 10 as per new requirements
    return 10;
};

// Function to create icon with specific image and progress styling
export const createIcon = (
    imageSrc: string,
    size = 40,
    borderColor = "#ffffff",
    _clusterCount?: number,
    isReached = false,
): import("leaflet").DivIcon | null => {
    const leaflet = getLeaflet();
    if (typeof window === "undefined" || !leaflet) {
        // Fallback icon for SSR
        return null;
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
    const hasImage = imageSrc && imageSrc.trim() !== "";

    const icon = leaflet.divIcon({
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
            padding: 4px;
            position: relative;
            overflow: hidden;
            transition: background-color 0.3s ease, border-color 0.3s ease;
          "
          onmouseover="this.style.background='#22c55e'; this.style.borderColor='#22c55e'; this.nextElementSibling.style.borderTopColor='#22c55e';"
          onmouseout="this.style.background='${isReached ? "#22c55e" : "white"}'; this.style.borderColor='${isReached ? "#22c55e" : "#ffffff"}'; this.nextElementSibling.style.borderTopColor='${isReached ? "#22c55e" : "white"}';"
          >
            ${
                hasImage
                    ? `
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
            `
                    : `
              <!-- Loading skeleton when no image -->
              <div style="
                width: 100%;
                height: 100%;
                border-radius: 12px;
                animation: skeleton-pulse 1.5s ease-in-out infinite;
              "></div>
              <style>
                @keyframes skeleton-pulse {
                  0% { background-color: #ffffff; }
                  50% { background-color: #f0f0f0; }
                  100% { background-color: #ffffff; }
                }
              </style>
            `
            }
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

// Calculate map center with first location positioned at 20% from right edge
export const getMapCenter = (
    photoClusters: JourneyPoint[][],
    journeyData: JourneyPoint[],
): [number, number] => {
    // If no clusters yet, check journey data
    if (photoClusters.length === 0) {
        const firstPoint = journeyData[0];
        if (!firstPoint) return [0, 0]; // Fallback, but map won't render anyway
        return [firstPoint.lat, firstPoint.lng];
    }

    // Start at first cluster center
    const firstCluster = photoClusters[0];
    if (!firstCluster || firstCluster.length === 0) return [0, 0]; // Fallback, but map won't render anyway

    const firstLat =
        firstCluster.reduce((sum, p) => sum + p.lat, 0) / firstCluster.length;
    const firstLng =
        firstCluster.reduce((sum, p) => sum + p.lng, 0) / firstCluster.length;

    // Position first location at 20% from right edge (80% from left)
    // At zoom level 10, each pixel represents approximately 152.87 meters
    // On mobile, timeline is at bottom so full width is available; on desktop, timeline takes up 50% of screen width
    // We want the first location to be at 20% from right of the visible map area
    // This means shifting map center left so marker appears more to the right

    const isMobile = isMobileDevice();
    const timelineWidthRatio = isMobile ? 0.0 : 0.5; // Mobile: full width, Desktop: timeline takes up 50% of screen

    // At zoom 10, approximately 0.35 degrees per 1000px at equator
    // For positioning, we need to shift the longitude to place marker at desired position
    const degreesPerPixelAtZoom10 = 0.35 / 1000; // rough approximation
    const basePixelsToShift =
        (window.innerWidth || 1400) * (1 - timelineWidthRatio);
    const pixelsToShiftFor20Percent = isMobile
        ? basePixelsToShift * 0.6 // Mobile: less aggressive positioning (60% instead of 300%)
        : basePixelsToShift * 3.0; // Desktop: 300% of visible map width to shift map left
    const lngShift = pixelsToShiftFor20Percent * degreesPerPixelAtZoom10;

    const adjustedLng = firstLng - lngShift;

    return [firstLat, adjustedLng];
};

// Calculate position for a location to be at 20% from right edge of visible map
export const getLocationPosition = (
    lat: number,
    lng: number,
): [number, number] => {
    // Position location at 20% from right edge (80% from left) of visible map area
    // On mobile, the timeline is at the bottom, not the side, so full width is available for map
    const isMobile = isMobileDevice();
    const timelineWidthRatio = isMobile ? 0.0 : 0.5; // Mobile: full width, Desktop: timeline takes up 50% of screen
    const degreesPerPixelAtZoom10 = 0.35 / 1000; // rough approximation at zoom 10

    // Calculate shift to position marker at 20% from right edge of visible map
    // Need to shift map center left so the marker appears more to the right
    // On mobile, use less aggressive positioning since we have full width
    const basePixelsToShift =
        (window.innerWidth || 1400) * (1 - timelineWidthRatio);
    const pixelsToShiftFor20Percent = isMobile
        ? basePixelsToShift * 0.6 // Mobile: less aggressive positioning (60% instead of 300%)
        : basePixelsToShift * 3.0; // Desktop: 300% of visible map width to shift map left
    const lngShift = pixelsToShiftFor20Percent * degreesPerPixelAtZoom10;

    return [lat, lng - lngShift];
};

// Calculate position for a location to be at 20% from right edge at a specific zoom level
export const getLocationPositionAtZoom = (
    lat: number,
    lng: number,
    zoom: number,
): [number, number] => {
    // Position location at 20% from right edge (80% from left) of visible map area
    // On mobile, the timeline is at the bottom, not the side, so full width is available for map
    const isMobile = isMobileDevice();
    const timelineWidthRatio = isMobile ? 0.0 : 0.5; // Mobile: full width, Desktop: timeline takes up 50% of screen

    // Scale the positioning offset based on zoom level
    // At higher zoom levels, we need less offset since we're more zoomed in
    const baseDegreesPerPixelAtZoom10 = 0.35 / 1000;
    const zoomScaleFactor = Math.pow(2, 10 - zoom); // Scale relative to zoom 10
    const degreesPerPixelAtCurrentZoom =
        baseDegreesPerPixelAtZoom10 * zoomScaleFactor;

    // Calculate shift to position marker at 20% from right edge of visible map
    // On mobile, use less aggressive positioning since we have full width
    const basePixelsToShift =
        (window.innerWidth || 1400) * (1 - timelineWidthRatio);
    const pixelsToShiftFor20Percent = isMobile
        ? basePixelsToShift * 0.6 // Mobile: less aggressive positioning (60% instead of 300%)
        : basePixelsToShift * 3.0; // Desktop: 300% of visible map width to shift map left
    const lngShift = pixelsToShiftFor20Percent * degreesPerPixelAtCurrentZoom;

    return [lat, lng - lngShift];
};
