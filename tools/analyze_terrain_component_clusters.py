"""Sweep AABB proximity thresholds for the Meshy terrain kit's loose islands."""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path


THRESHOLDS = (0.0, 0.001, 0.0025, 0.005, 0.01, 0.02, 0.035, 0.05, 0.075)


class UnionFind:
    def __init__(self, count: int) -> None:
        self.parent = list(range(count))
        self.rank = [0] * count

    def find(self, value: int) -> int:
        while self.parent[value] != value:
            self.parent[value] = self.parent[self.parent[value]]
            value = self.parent[value]
        return value

    def union(self, left: int, right: int) -> None:
        left_root = self.find(left)
        right_root = self.find(right)
        if left_root == right_root:
            return
        if self.rank[left_root] < self.rank[right_root]:
            left_root, right_root = right_root, left_root
        self.parent[right_root] = left_root
        if self.rank[left_root] == self.rank[right_root]:
            self.rank[left_root] += 1


def aabb_distance(left: dict, right: dict) -> float:
    left_min = left["bounds"]["min"]
    left_max = left["bounds"]["max"]
    right_min = right["bounds"]["min"]
    right_max = right["bounds"]["max"]
    squared = 0.0
    for axis in range(3):
        gap = max(left_min[axis] - right_max[axis], right_min[axis] - left_max[axis], 0.0)
        squared += gap * gap
    return math.sqrt(squared)


def summarize(parts: list[dict], threshold: float, pairs: list[tuple[float, int, int]]) -> dict:
    union_find = UnionFind(len(parts))
    for distance, left, right in pairs:
        if distance > threshold:
            break
        union_find.union(left, right)

    members: dict[int, list[int]] = {}
    for index in range(len(parts)):
        members.setdefault(union_find.find(index), []).append(index)

    clusters = []
    for indices in members.values():
        polygons = sum(int(parts[index]["polygons"]) for index in indices)
        minimum = [min(parts[index]["bounds"]["min"][axis] for index in indices) for axis in range(3)]
        maximum = [max(parts[index]["bounds"]["max"][axis] for index in indices) for axis in range(3)]
        clusters.append(
            {
                "islands": len(indices),
                "polygons": polygons,
                "center": [round((minimum[axis] + maximum[axis]) * 0.5, 4) for axis in range(3)],
                "size": [round(maximum[axis] - minimum[axis], 4) for axis in range(3)],
                "member_indices": [int(parts[index]["index"]) for index in indices],
            }
        )
    clusters.sort(key=lambda item: item["polygons"], reverse=True)
    return {
        "threshold": threshold,
        "cluster_count": len(clusters),
        "clusters_over_1000_polygons": sum(cluster["polygons"] >= 1000 for cluster in clusters),
        "largest_clusters": clusters[:15],
    }


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: analyze_terrain_component_clusters.py loose-parts.json report.json")
    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    parts = json.loads(source.read_text(encoding="utf-8"))
    pairs = []
    for left in range(len(parts)):
        for right in range(left + 1, len(parts)):
            pairs.append((aabb_distance(parts[left], parts[right]), left, right))
    pairs.sort(key=lambda item: item[0])
    report = [summarize(parts, threshold, pairs) for threshold in THRESHOLDS]
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2), encoding="utf-8")
    for entry in report:
        largest = entry["largest_clusters"][:9]
        polygon_totals = ", ".join(str(cluster["polygons"]) for cluster in largest)
        print(
            f"threshold={entry['threshold']:.4f} clusters={entry['cluster_count']} "
            f"substantial={entry['clusters_over_1000_polygons']} top9=[{polygon_totals}]"
        )


if __name__ == "__main__":
    main()
