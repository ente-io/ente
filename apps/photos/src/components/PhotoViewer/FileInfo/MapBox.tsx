import { useEffect, useRef } from 'react';
import { Typography, styled } from '@mui/material';
import { runningInBrowser } from 'utils/common';

import 'leaflet/dist/leaflet.css';
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css'; // Re-uses images from ~leaflet package
import { t } from 'i18next';
runningInBrowser() && require('leaflet-defaulticon-compatibility');
const L = runningInBrowser()
    ? (require('leaflet') as typeof import('leaflet'))
    : null;

const LAYER_TILE_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const LAYER_TILE_ATTRIBUTION =
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const ZOOM_LEVEL = 16;

const MapBoxContainer = styled('div')`
    height: 200px;
    width: 100%;
`;

interface MapBoxProps {
    location: { latitude: number; longitude: number };
    showMap: boolean;
}

const MapBox: React.FC<MapBoxProps> = ({ location, showMap }) => {
    const mapBoxContainerRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (showMap) {
            const mapContainer = mapBoxContainerRef.current;
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
        }
    }, []);

    return (
        <>
            <MapBoxContainer ref={showMap && mapBoxContainerRef}>
                {showMap && <Typography> {t('ENABLE_MAP')}</Typography>}
            </MapBoxContainer>
        </>
    );
};

export default MapBox;
