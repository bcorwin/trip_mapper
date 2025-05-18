import re
import csv
import json
import argparse
import xml.etree.cElementTree as ET

# TODO: Update stops.csv
# TODO: Include Palmira to stops.csv
# TODO: add version and schema location to gpx element


def extract_lat_lon(location):
  out = re.sub(r"[^0-9\.\-,]", "", location)
  return out.split(",")


def main(input_file, output_file):
  with open("travel_dates.txt", "r") as f:
    travel_dates = f.read().splitlines()

  with open(input_file, "r") as f:
    data = json.load(f)

  gpx = ET.Element("gpx")

  with open("stops.csv", newline="") as f:
    csv_reader = csv.reader(f)
    for row in csv_reader:
      if row[0] == "index":
        continue
      wpt_name = row[3]
      wpt_time = row[4]
      wpt_lat = row[6]
      wpt_lon = row[7]
      if wpt_lat == "" or wpt_lon == "":
        continue
      if wpt_time[0:10] < "2023-07-10":
        wpt_time = "2023-07-10T10:03:00.000-04:00"
      wpt = ET.SubElement(gpx, "wpt", lat=wpt_lat, lon=wpt_lon)
      ET.SubElement(wpt, "time").text = wpt_time
      ET.SubElement(wpt, "name").text = wpt_name

  track = ET.SubElement(gpx, "trk")
  track_segment = ET.SubElement(track, "trkseg")
  for item in data["semanticSegments"]:
    if "timelinePath" in item:
      path_points = item["timelinePath"]
      for point in path_points:
        timestamp = point["time"]  # TODO: Convert to UTC after filtering
        date = timestamp[0:10]
        if date < "2023-07-10":
          continue
        elif date not in travel_dates:
          continue
        elif timestamp == "2023-10-06T08:27:00.000-04:00":
          # Weird glitch where it goes from Idaho to Yellowstone
          continue
        lat, lon = extract_lat_lon(point["point"])
        track_point = ET.SubElement(track_segment, "trkpt", lat=lat, lon=lon)
        ET.SubElement(track_point, "time").text = timestamp

  tree = ET.ElementTree(gpx)
  ET.indent(tree, space="  ")
  tree.write(f"{output_file}.gpx")


if __name__ == "__main__":
  # Example usage: process_timeline.py Timeline.json test_20250518
  parser = argparse.ArgumentParser(description="Convert JSON to GPX.")
  parser.add_argument("input_file", help="Input JSON file")
  parser.add_argument("output_file", help="Output GPX file")
  args = parser.parse_args()

  main(args.input_file, args.output_file)
