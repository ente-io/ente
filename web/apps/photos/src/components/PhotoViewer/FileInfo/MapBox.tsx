import { styled } from "@mui/material";
import { useEffect, useRef } from "react";
import { runningInBrowser } from "utils/common";
import { MapButton } from "./MapButton";

import { t } from "i18next";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css"; // Re-uses images from ~leaflet package
import "leaflet/dist/leaflet.css";
runningInBrowser() && require("leaflet-defaulticon-compatibility");
const L = runningInBrowser()
    ? (require("leaflet") as typeof import("leaflet"))
    : null;

const LAYER_TILE_URL = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
const LAYER_TILE_ATTRIBUTION =
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const ZOOM_LEVEL = 16;

const MapBoxContainer = styled("div")`
    height: 200px;
    width: 100%;
`;
const MapBoxEnableContainer = styled(MapBoxContainer)`
    position: relative;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: rgba(255, 255, 255, 0.09);
`;

interface MapBoxProps {
    location: { latitude: number; longitude: number };
    mapEnabled: boolean;
    openUpdateMapConfirmationDialog: () => void;
}

const MapBox: React.FC<MapBoxProps> = ({
    location,
    mapEnabled,
    openUpdateMapConfirmationDialog,
}) => {
    const mapBoxContainerRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const mapContainer = mapBoxContainerRef.current;
        if (mapEnabled) {
            const position: L.LatLngTuple = [
                location.latitude,
                location.longitude,
            ];
            if (mapContainer && !mapContainer.hasChildNodes()) {
                const map = L.map(mapContainer).setView(position, ZOOM_LEVEL);
                L.tileLayer(LAYER_TILE_URL, {
                    attribution: LAYER_TILE_ATTRIBUTION,
                }).addTo(map);
                L.marker(position).addTo(map).openPopup();
            }
        } else {
            if (mapContainer && mapContainer.hasChildNodes()) {
                if (mapContainer.firstChild) {
                    mapContainer.removeChild(mapContainer.firstChild);
                }
            }
        }
    }, [mapEnabled]);

    return mapEnabled ? (
        <MapBoxContainer ref={mapBoxContainerRef} />
    ) : (
        <MapBoxEnableContainer>
            <MapButton onClick={openUpdateMapConfirmationDialog}>
                {" "}
                {t("ENABLE_MAP")}
            </MapButton>
        </MapBoxEnableContainer>
    );
};

export default MapBox;
