import AddIcon from "@mui/icons-material/Add";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import DoneIcon from "@mui/icons-material/Done";
import RemoveIcon from "@mui/icons-material/Remove";
import {
    Box,
    Button,
    CircularProgress,
    Dialog,
    IconButton,
    Stack,
    styled,
    Typography,
    type DialogProps,
} from "@mui/material";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { haveWindow } from "ente-base/env";
import type { Location } from "ente-base/types";
import type { EnteFile } from "ente-media/file";
import { fileLocation } from "ente-media/file-metadata";
import { t } from "i18next";
import React, { useEffect, useMemo, useRef, useState } from "react";

import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css";
import "leaflet/dist/leaflet.css";
// eslint-disable-next-line @typescript-eslint/no-require-imports, @typescript-eslint/no-unused-expressions
haveWindow() && require("leaflet-defaulticon-compatibility");
const leaflet = haveWindow()
    ? // eslint-disable-next-line @typescript-eslint/no-require-imports
      (require("leaflet") as typeof import("leaflet"))
    : null;

export interface EditLocationDialogProps extends ModalVisibilityProps {
    /**
     * The files whose location we want to edit.
     */
    files: EnteFile[];
    /**
     * Called when the user confirms the location update.
     *
     * @param location The new location to set for all selected files.
     * @returns A promise that resolves when the update is complete.
     */
    onConfirm: (location: Location) => Promise<void>;
}

/**
 * A full-screen dialog with an interactive map where users can drop a pin to
 * set the location for one or more photos.
 */
export const EditLocationDialog: React.FC<EditLocationDialogProps> = ({
    open,
    onClose,
    files,
    onConfirm,
}) => {
    const [selectedLocation, setSelectedLocation] = useState<
        Location | undefined
    >(undefined);
    const [isLoading, setIsLoading] = useState(false);
    const [isSuccess, setIsSuccess] = useState(false);

    // Get initial location only if a single file is selected
    const initialLocation = useMemo(() => {
        if (files.length !== 1) return undefined;
        const file = files[0];
        return file ? fileLocation(file) : undefined;
    }, [files]);

    // Capture whether we're adding (vs editing) when dialog opens
    const [isAddingLocation, setIsAddingLocation] = useState(false);

    // Reset selected location and states only when dialog opens
    const prevOpenRef = useRef(false);
    useEffect(() => {
        if (open && !prevOpenRef.current) {
            setSelectedLocation(initialLocation);
            setIsLoading(false);
            setIsSuccess(false);
            // Determine add vs edit based on whether any file has location at open time
            setIsAddingLocation(!files.some((file) => fileLocation(file)));
        }
        prevOpenRef.current = open;
    }, [open, initialLocation, files]);

    const hasLocationChanged = useMemo(() => {
        if (!selectedLocation) return false;
        if (!initialLocation) return true;
        return (
            selectedLocation.latitude !== initialLocation.latitude ||
            selectedLocation.longitude !== initialLocation.longitude
        );
    }, [selectedLocation, initialLocation]);

    // Reset success state when user selects a new location
    const prevSelectedLocationRef = useRef(selectedLocation);
    useEffect(() => {
        const prevLoc = prevSelectedLocationRef.current;
        const currLoc = selectedLocation;
        const locationChanged =
            prevLoc?.latitude !== currLoc?.latitude ||
            prevLoc?.longitude !== currLoc?.longitude;

        if (isSuccess && locationChanged) {
            setIsSuccess(false);
        }
        prevSelectedLocationRef.current = selectedLocation;
    }, [isSuccess, selectedLocation]);

    const handleConfirm = async () => {
        if (selectedLocation && hasLocationChanged && !isLoading) {
            setIsLoading(true);
            setIsSuccess(false);
            try {
                await onConfirm(selectedLocation);
                setIsSuccess(true);
            } finally {
                setIsLoading(false);
            }
        }
    };

    return (
        <FullScreenDialog open={open} onClose={onClose}>
            <Stack sx={{ height: "100%", width: "100%" }}>
                <TitleBar
                    onBack={onClose}
                    onConfirm={handleConfirm}
                    canConfirm={hasLocationChanged}
                    isLoading={isLoading}
                    isSuccess={isSuccess}
                    isAddingLocation={isAddingLocation}
                />
                <Box sx={{ flex: 1, position: "relative" }}>
                    <EditableMap
                        initialLocation={initialLocation}
                        selectedLocation={selectedLocation}
                        onLocationSelect={setSelectedLocation}
                    />
                </Box>
            </Stack>
        </FullScreenDialog>
    );
};

const FullScreenDialog = styled((props: DialogProps) => (
    <Dialog fullScreen {...props} />
))({
    "& .MuiDialog-paper": {
        backgroundColor: "var(--mui-palette-background-default)",
    },
});

interface TitleBarProps {
    onBack: () => void;
    onConfirm: () => void;
    canConfirm: boolean;
    isLoading: boolean;
    isSuccess: boolean;
    isAddingLocation: boolean;
}

const TitleBar: React.FC<TitleBarProps> = ({
    onBack,
    onConfirm,
    canConfirm,
    isLoading,
    isSuccess,
    isAddingLocation,
}) => (
    <Stack
        direction="row"
        sx={{
            alignItems: "center",
            gap: 1,
            p: 1,
            borderBottom: "1px solid",
            borderColor: "divider",
        }}
    >
        <IconButton onClick={onBack} aria-label={t("close")}>
            <ArrowBackIcon />
        </IconButton>
        <Typography variant="h6" sx={{ flex: 1 }}>
            {t(isAddingLocation ? "add_location" : "edit_location")}
        </Typography>
        {isLoading ? (
            <Box
                sx={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    px: 2,
                }}
            >
                <CircularProgress size={24} />
            </Box>
        ) : isSuccess ? (
            <Box
                sx={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    px: 2,
                    color: "success.main",
                }}
            >
                <DoneIcon />
            </Box>
        ) : (
            <Button
                onClick={onConfirm}
                disabled={!canConfirm}
                variant="contained"
                color="accent"
            >
                {t("save_location")}
            </Button>
        )}
    </Stack>
);

interface EditableMapProps {
    initialLocation: Location | undefined;
    selectedLocation: Location | undefined;
    onLocationSelect: (location: Location) => void;
}

const EditableMap: React.FC<EditableMapProps> = ({
    initialLocation,
    selectedLocation,
    onLocationSelect,
}) => {
    const mapContainerRef = useRef<HTMLDivElement>(null);
    const mapRef = useRef<L.Map | null>(null);
    const markerRef = useRef<L.Marker | null>(null);
    // Capture initial location at mount time to avoid map reset on file updates
    const initialLocationRef = useRef(initialLocation);

    const urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
    const attribution =
        '&copy; <a target="_blank" rel="noopener" href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';

    useEffect(() => {
        const mapContainer = mapContainerRef.current;
        if (!mapContainer || !leaflet) return;

        // Don't recreate map if it already exists
        if (mapRef.current) return;

        // Use the captured initial location from mount time
        const initLoc = initialLocationRef.current;
        const initialLat = initLoc?.latitude;
        const initialLng = initLoc?.longitude;

        // Determine initial view
        const defaultCenter: L.LatLngTuple = [20, 0]; // World view
        const defaultZoom = 3;

        const hasInitialLocation =
            initialLat !== undefined && initialLng !== undefined;
        const center: L.LatLngTuple = hasInitialLocation
            ? [initialLat, initialLng]
            : defaultCenter;
        const zoom = hasInitialLocation ? 6 : defaultZoom;

        // Create map with zoom control disabled (we add custom controls)
        const map = leaflet
            .map(mapContainer, { zoomControl: false })
            .setView(center, zoom);
        leaflet.tileLayer(urlTemplate, { attribution }).addTo(map);
        mapRef.current = map;

        // Add initial marker if location exists
        if (hasInitialLocation) {
            const marker = leaflet
                .marker([initialLat, initialLng], { draggable: true })
                .addTo(map);
            markerRef.current = marker;

            marker.on("dragend", () => {
                const pos = marker.getLatLng();
                onLocationSelect({ latitude: pos.lat, longitude: pos.lng });
            });
        }

        // Handle map clicks to place/move marker
        map.on("click", (e: L.LeafletMouseEvent) => {
            const { lat, lng } = e.latlng;
            onLocationSelect({ latitude: lat, longitude: lng });

            if (markerRef.current) {
                markerRef.current.setLatLng([lat, lng]);
            } else {
                const marker = leaflet
                    .marker([lat, lng], { draggable: true })
                    .addTo(map);
                markerRef.current = marker;

                marker.on("dragend", () => {
                    const pos = marker.getLatLng();
                    onLocationSelect({ latitude: pos.lat, longitude: pos.lng });
                });
            }
        });

        return () => {
            if (mapRef.current) {
                mapRef.current.remove();
                mapRef.current = null;
                markerRef.current = null;
            }
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    // Update marker position when selectedLocation changes externally
    useEffect(() => {
        if (
            selectedLocation &&
            markerRef.current &&
            mapRef.current &&
            leaflet
        ) {
            const currentPos = markerRef.current.getLatLng();
            if (
                currentPos.lat !== selectedLocation.latitude ||
                currentPos.lng !== selectedLocation.longitude
            ) {
                markerRef.current.setLatLng([
                    selectedLocation.latitude,
                    selectedLocation.longitude,
                ]);
            }
        }
    }, [selectedLocation]);

    const handleZoomIn = (e: React.MouseEvent) => {
        e.stopPropagation();
        mapRef.current?.zoomIn();
    };
    const handleZoomOut = (e: React.MouseEvent) => {
        e.stopPropagation();
        mapRef.current?.zoomOut();
    };

    return (
        <MapWrapper>
            <MapContainer ref={mapContainerRef} />
            <MapOverlay>
                {selectedLocation ? (
                    <Typography variant="body" sx={{ color: "text.muted" }}>
                        {selectedLocation.latitude.toFixed(6)},{" "}
                        {selectedLocation.longitude.toFixed(6)}
                    </Typography>
                ) : (
                    <Typography variant="body" sx={{ color: "text.muted" }}>
                        {t("tap_to_select_location")}
                    </Typography>
                )}
            </MapOverlay>
            <ZoomControls>
                <ZoomButton onClick={handleZoomIn} aria-label={t("zoom_in")}>
                    <AddIcon />
                </ZoomButton>
                <ZoomButton onClick={handleZoomOut} aria-label={t("zoom_out")}>
                    <RemoveIcon />
                </ZoomButton>
            </ZoomControls>
        </MapWrapper>
    );
};

const MapWrapper = styled("div")({
    height: "100%",
    width: "100%",
    position: "relative",
});

const MapContainer = styled("div")({ height: "100%", width: "100%" });

const MapOverlay = styled("div")(({ theme }) => ({
    position: "absolute",
    top: theme.spacing(2),
    left: "50%",
    transform: "translateX(-50%)",
    zIndex: 1000,
    backgroundColor: theme.vars.palette.background.paper,
    padding: theme.spacing(1, 2),
    borderRadius: "9999px",
    boxShadow: theme.shadows[2],
}));

const ZoomControls = styled(Stack)(({ theme }) => ({
    position: "absolute",
    right: theme.spacing(3),
    bottom: theme.spacing(6),
    zIndex: 1000,
    gap: theme.spacing(1),
}));

const ZoomButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: theme.vars.palette.background.paper,
    boxShadow: theme.shadows[4],
    width: 48,
    height: 48,
    borderRadius: 16,
    transition: "transform 0.2s ease-out",
    "&:hover": {
        backgroundColor: theme.vars.palette.background.paper,
        transform: "scale(1.05)",
    },
}));
