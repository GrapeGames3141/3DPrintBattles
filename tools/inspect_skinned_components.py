import bpy
import json
import mathutils
import os
import sys


def find(parent, item):
    while parent[item] != item:
        parent[item] = parent[parent[item]]
        item = parent[item]
    return item


def union(parent, sizes, left, right):
    left_root = find(parent, left)
    right_root = find(parent, right)
    if left_root == right_root:
        return
    if sizes[left_root] < sizes[right_root]:
        left_root, right_root = right_root, left_root
    parent[right_root] = left_root
    sizes[left_root] += sizes[right_root]


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 2:
        raise SystemExit("Expected: animated.glb report.json")
    source_path, report_path = args

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_path)
    mesh_obj = next(
        obj for obj in bpy.context.scene.objects
        if obj.type == "MESH" and obj.name.casefold() != "icosphere"
    )
    mesh = mesh_obj.data
    parent = list(range(len(mesh.vertices)))
    sizes = [1] * len(mesh.vertices)
    for edge in mesh.edges:
        union(parent, sizes, edge.vertices[0], edge.vertices[1])

    components = {}
    for vertex in mesh.vertices:
        root = find(parent, vertex.index)
        components.setdefault(root, []).append(vertex.index)

    report = []
    for indices in components.values():
        if len(indices) < 20:
            continue
        points = [mesh_obj.matrix_world @ mesh.vertices[index].co for index in indices]
        mins = [min(point[axis] for point in points) for axis in range(3)]
        maxs = [max(point[axis] for point in points) for axis in range(3)]
        group_weights = {}
        for index in indices:
            for assignment in mesh.vertices[index].groups:
                group_name = mesh_obj.vertex_groups[assignment.group].name
                group_weights[group_name] = group_weights.get(group_name, 0.0) + assignment.weight
        weight_total = sum(group_weights.values()) or 1.0
        top_groups = sorted(group_weights.items(), key=lambda item: item[1], reverse=True)[:8]
        report.append({
            "vertex_count": len(indices),
            "indices": indices,
            "min": [round(value, 6) for value in mins],
            "max": [round(value, 6) for value in maxs],
            "center": [round((mins[axis] + maxs[axis]) * 0.5, 6) for axis in range(3)],
            "size": [round(maxs[axis] - mins[axis], 6) for axis in range(3)],
            "top_groups": [
                {"name": name, "share": round(weight / weight_total, 5)}
                for name, weight in top_groups
            ],
        })

    report.sort(key=lambda component: component["vertex_count"], reverse=True)
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
