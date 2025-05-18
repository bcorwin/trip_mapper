import csv
import json
import pandas as pd

with open("0qMwrQwk.json", encoding="utf8") as f:
  json_data = json.load(f)

lists = pd.DataFrame(json_data["lists"])
lists = lists.set_index("id").name.to_dict()

cards = pd.DataFrame(json_data["cards"])
cards = cards[[
  "id",
  "closed",
  "coordinates",
  "due",
  "idList",
  "labels",
  "name",
  "start",
]]
cards = (
  cards
  .assign(list=lambda df: df.idList.map(lists))
)

board_cards = [
  (
    x["id"],
    x["name"],
    x.get("start"),
    x.get("due"),
    (x.get("coordinates") or {}).get("latitude"),
    (x.get("coordinates") or {}).get("longitude"),
    x["closed"],
    lists[x["idList"]],
  ) for x in json_data["cards"] if not x["closed"]
]
# board_cards = [x for x in board_cards if x[-1] in ("Done", "Booked")]

column_names = (
  "id",
  "name",
  "start_date",
  "end_date",
  "latitude",
  "longitude",
  "archived",
  "list",
)

stops = pd.DataFrame(board_cards, columns=column_names)

with open("stops.csv", "w") as f:
  wr = csv.writer(f)
  wr.writerow(column_names)
  wr.writerows(board_cards)
