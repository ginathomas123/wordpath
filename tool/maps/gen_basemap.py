#!/usr/bin/env python3
"""Clip + simplify Natural Earth land polygons to the biblical world, baking a
tiny basemap.json for the stylized atlas. Natural Earth is public domain.

Output: assets/maps/basemap.json — {"bbox":[lonMin,latMin,lonMax,latMax],
"land":[ [ [lon,lat], ... ], ... ]}
"""
import json
import sys

SRC = sys.argv[1]
OUT = "assets/maps/basemap.json"

LON_MIN, LON_MAX = 10.0, 52.0
LAT_MIN, LAT_MAX = 22.0, 46.0
EPS = 0.03  # Douglas-Peucker tolerance in degrees (~3 km)


def clip(poly, edge):
    """Sutherland–Hodgman clip of a ring against one rectangle edge."""
    out = []
    n = len(poly)
    for i in range(n):
        cur = poly[i]
        prv = poly[i - 1]
        cin = inside(cur, edge)
        pin = inside(prv, edge)
        if cin:
            if not pin:
                out.append(intersect(prv, cur, edge))
            out.append(cur)
        elif pin:
            out.append(intersect(prv, cur, edge))
    return out


def inside(p, edge):
    k, v, sign = edge
    return p[k] >= v if sign > 0 else p[k] <= v


def intersect(a, b, edge):
    k, v, _ = edge
    o = 1 - k
    if b[k] == a[k]:
        return [v, a[o]] if k == 0 else [a[o], v]
    t = (v - a[k]) / (b[k] - a[k])
    x = a[0] + t * (b[0] - a[0])
    y = a[1] + t * (b[1] - a[1])
    return [x, y]


def clip_ring(ring):
    edges = [(0, LON_MIN, 1), (0, LON_MAX, -1), (1, LAT_MIN, 1), (1, LAT_MAX, -1)]
    for e in edges:
        if not ring:
            return []
        ring = clip(ring, e)
    return ring


def perp(pt, a, b):
    if a == b:
        return ((pt[0] - a[0]) ** 2 + (pt[1] - a[1]) ** 2) ** 0.5
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = ((pt[0] - a[0]) * dx + (pt[1] - a[1]) * dy) / (dx * dx + dy * dy)
    px, py = a[0] + t * dx, a[1] + t * dy
    return ((pt[0] - px) ** 2 + (pt[1] - py) ** 2) ** 0.5


def dp(points, eps):
    if len(points) < 3:
        return points
    dmax, idx = 0, 0
    for i in range(1, len(points) - 1):
        d = perp(points[i], points[0], points[-1])
        if d > dmax:
            dmax, idx = d, i
    if dmax > eps:
        left = dp(points[:idx + 1], eps)
        right = dp(points[idx:], eps)
        return left[:-1] + right
    return [points[0], points[-1]]


def rings_from(geom):
    t = geom["type"]
    if t == "Polygon":
        yield geom["coordinates"][0]
    elif t == "MultiPolygon":
        for poly in geom["coordinates"]:
            yield poly[0]


def main():
    data = json.load(open(SRC, encoding="utf-8"))
    sys.setrecursionlimit(100000)
    land = []
    for feat in data["features"]:
        for ring in rings_from(feat["geometry"]):
            clipped = clip_ring([[c[0], c[1]] for c in ring])
            if len(clipped) < 3:
                continue
            simp = dp(clipped, EPS)
            if len(simp) >= 3:
                land.append([[round(x, 3), round(y, 3)] for x, y in simp])

    out = {"bbox": [LON_MIN, LAT_MIN, LON_MAX, LAT_MAX], "land": land}
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, separators=(",", ":"))
    pts = sum(len(r) for r in land)
    print(f"wrote {len(land)} land rings, {pts} points to {OUT}")


if __name__ == "__main__":
    main()
