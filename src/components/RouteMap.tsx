import { MapContainer, TileLayer } from 'react-leaflet';

const position: [number, number] = [38, -98]; // Center of US

export default function RouteMap() {
  return (
    <MapContainer center={position} zoom={5} style={{ height: "100vh", width: "100%" }}>
      <TileLayer
        attribution='&copy; OpenStreetMap contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
    </MapContainer>
  );
}
