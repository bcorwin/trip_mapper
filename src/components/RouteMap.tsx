import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer, Polyline } from 'react-leaflet';
import gpxParser from "gpxparser";

type LatLngTuple = [number, number];

const position: [number, number] = [38, -98]; // Center of USA
const gpx_data = "/route.gpx";

export default function RouteMap() {
  const [trackPoints, setTrackPoints] = useState<LatLngTuple[]>([]);

  useEffect(() => {
    const fetchAndParseGpx = async () => {
      const response = await fetch(gpx_data);
      const gpxText = await response.text();
      const gpx = new gpxParser();
      gpx.parse(gpxText);

      // Extract all points from all tracks and segments
      const points: LatLngTuple[] = [];
      gpx.tracks.forEach(track => {
        track.points.forEach(pt => {
          points.push([pt.lat, pt.lon]);
        });
      });
      setTrackPoints(points);
    };

    fetchAndParseGpx();
  }, []);

  if (trackPoints.length === 0) return <div>Loading map...</div>;

  return (
    <MapContainer center={position} zoom={5} style={{ height: "100vh", width: "100%" }}>
      <TileLayer
        attribution='&copy; OpenStreetMap contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Polyline positions={trackPoints} color="blue" />
    </MapContainer>
  );
};
