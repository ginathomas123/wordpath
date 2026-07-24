#!/usr/bin/env python3
"""Generate a curated places.json for the Bible atlas from OpenBible.info's
Bible Geocoding data (CC-BY-4.0, https://github.com/openbibleinfo).

Input: the 2007 `merged.txt` gazetteer (name, optional root, lat, lon, verses).
Output: assets/maps/places.json — a curated set of well-known places with
coordinates and an `approx` flag derived from OpenBible's ~ / < / > / ? markers.
"""
import json
import re
import sys

SRC = sys.argv[1]
OUT = "assets/maps/places.json"

# A coordinate token: optional ~ < > prefix, a decimal number, optional trailing ?
COORD = re.compile(r'^[~<>]?-?\d+\.\d+\??$')
REF = re.compile(r'\b(?:[1-3]\s)?[A-Z][a-z]+\.?\s\d+:\d+')

# NT / journey places worth guaranteeing even if their OT ref-count is low.
MUST = {
    "jerusalem","bethlehem","nazareth","capernaum","jericho","bethany","hebron",
    "samaria","shechem","bethel","beersheba","dan","jordan","galilee","sinai",
    "horeb","egypt","babylon","nineveh","ur","haran","damascus","antioch","tarsus",
    "ephesus","smyrna","pergamum","colossae","laodicea","philadelphia","sardis",
    "thyatira","miletus","troas","philippi","thessalonica","berea","athens",
    "corinth","cenchreae","rome","malta","cyprus","paphos","crete","patmos",
    "caesarea","joppa","lydda","emmaus","cana","bethsaida","tyre","sidon","gaza",
    "carmel","moab","edom","midian","assyria","gilead","bashan","shiloh","gibeon",
}


def parse_coord(tok):
    approx = tok[0] in "~<>" or tok.endswith("?")
    val = float(tok.lstrip("~<>").rstrip("?"))
    return val, approx


def main():
    places = {}  # name -> dict
    with open(SRC, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            toks = line.split()
            # Find the lat/lon pair (first two consecutive decimal-coord tokens).
            ci = None
            for i in range(1, len(toks) - 1):
                if COORD.match(toks[i]) and COORD.match(toks[i + 1]):
                    ci = i
                    break
            if ci is None:
                continue
            name = toks[0]
            lat, a1 = parse_coord(toks[ci])
            lon, a2 = parse_coord(toks[ci + 1])
            # Sanity: keep the broad biblical world only.
            if not (5 <= lat <= 60 and 5 <= lon <= 60):
                continue
            rest = " ".join(toks[ci + 2:])
            refcount = len(REF.findall(rest))
            key = name.lower()
            prev = places.get(key)
            if prev is None or refcount > prev["refs"]:
                places[key] = {
                    "name": name,
                    "lat": round(lat, 4),
                    "lon": round(lon, 4),
                    "approx": bool(a1 or a2),
                    "refs": refcount,
                }

    ranked = sorted(places.values(), key=lambda p: p["refs"], reverse=True)
    chosen = {p["name"].lower(): p for p in ranked[:150]}
    for key, p in places.items():
        if key in MUST and key not in chosen:
            chosen[key] = p

    out = sorted(chosen.values(), key=lambda p: p["name"])
    for p in out:
        del p["refs"]

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {len(out)} places to {OUT}")
    print("sample:", ", ".join(p["name"] for p in out[:12]))


if __name__ == "__main__":
    main()
