import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer } from 'react-leaflet';
import { Hotline, Color } from 'react-leaflet-hotline';
import gpxParser from "gpxparser";

type HotlineValues = {
  lat: number,
  lng: number,
  val: number,
};

const position: [number, number] = [38, -98]; // Center of USA
const gpx_data = "/route.gpx";
const end_date = new Date('2025-01-01');

export default function RouteMap() {
  const [trackPoints, setTrackPoints] = useState<HotlineValues[]>([]);

  useEffect(() => {
    const fetchAndParseGpx = async () => {
      const response = await fetch(gpx_data);
      const gpxText = await response.text();
      const gpx = new gpxParser();
      gpx.parse(gpxText);

      // Extract all points from all tracks and segments
      const points:HotlineValues[]  = [];
      gpx.tracks.forEach(track => {
        track.points.forEach(pt => {
          let point_date = new Date(pt.time)
          if(point_date <= end_date) {
            const val = (Number(point_date) - 1688997780000) / (1728846660000 - 1688997780000);
            points.push({lat: pt.lat, lng: pt.lon, val: val});
          }
        });
      });
      setTrackPoints(points);
    };

    fetchAndParseGpx();
  }, []);

  return (
    <MapContainer center={position} zoom={5} style={{ height: "100vh", width: "100%" }}>
      <TileLayer
        attribution='&copy; OpenStreetMap contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Hotline
        data={trackPoints}
        getLat={({ point }) => point.lat}
        getLng={({ point }) => point.lng}
        getVal={({ point }) => point.val}
        options={{
          palette: [
            { r:  27, g: 158, b: 119, t: 0.0 },
            { r: 217, g:  95, b:   2, t: 0.5 },
            { r: 117, g: 112, b: 179, t: 1.0 },
          ] as Color[],
          weight: 5,
          outlineWidth: 1,
          outlineColor: 'black',
        }}
      />
    </MapContainer>
  );
};
