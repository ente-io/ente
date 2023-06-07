import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';
import { runningInBrowser } from 'utils/common';
import 'leaflet/dist/leaflet.css';
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css'; // Re-uses images from ~leaflet package
const L = runningInBrowser() ? require('leaflet') : null;
runningInBrowser() ? require('leaflet-defaulticon-compatibility') : null;

interface MapBoxProps {
    location: { latitude: number; longitude: number };
}

const MapBox: React.FC<MapBoxProps> = ({ location }) => {
    const [isClient, setIsClient] = useState(false);
    const position: [number, number] = [location.latitude, location.longitude];

    useEffect(() => {
        setIsClient(true);
    }, []);

    useEffect(() => {
        if (isClient) {
            const mapContainer = document.getElementById('map-container');
            if (mapContainer && !mapContainer.hasChildNodes()) {
                const map = L.map(mapContainer).setView(position, 13);

                L.tileLayer(
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    {
                        attribution:
                            '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                    }
                ).addTo(map);

                L.marker(position)
                    .addTo(map)
                    .bindPopup('You were here.')
                    .openPopup();
            }
        }
    }, [isClient, position]);

    if (!isClient) {
        return null; // Render nothing on the server-side
    }

    return (
        <div
            id="map-container"
            style={{ height: '200px', width: '100%' }}></div>
    );
};

export default dynamic(() => Promise.resolve(MapBox), { ssr: false });
