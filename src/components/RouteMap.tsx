import React, { useEffect, useState, WheelEvent } from "react";
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
const date_range = [
  new Date('2023-07-10'),
  new Date('2024-10-14')
];

function clamp(val:number, min:number, max:number) {
  return Math.min(Math.max(val, min), max);
}

export default function RouteMap() {
  const [trackPoints, setTrackPoints] = useState<HotlineValues[]>([]);
  const [endDate, setEndDate] = useState<Date>(date_range[0]);

  function handleWheel(event: WheelEvent<HTMLDivElement>) {
    event.preventDefault(); // Prevents default scrolling behavior
    // TODO: Go through travel dates instead?
    const dayDelta = 7*4;
    let newDate = clamp(
      endDate.getTime() + Math.sign(event.deltaY)*dayDelta*(1000 * 60 * 60 * 24),
      Number(date_range[0]),
      Number(date_range[1])
    );
    setEndDate(new Date(newDate))
    console.log(endDate)
  };

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
          if(point_date <= endDate) {
            const val = (Number(point_date) - 1688997780000) / (1728846660000 - 1688997780000);
            points.push({lat: pt.lat, lng: pt.lon, val: val});
          }
        });
      });
      setTrackPoints(points);
    };

    fetchAndParseGpx();
  }, [endDate]);

  return (
    <div onWheel={handleWheel}>
      <MapContainer
        center={position}
        zoom={5}
        style={{ height: "100vh", width: "100%" }}
        dragging={false}
        touchZoom={false}
        scrollWheelZoom={false}
        doubleClickZoom={false}
        boxZoom={false}
        keyboard={false}
        zoomControl={false}
      >
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
    </div>
  );
};
