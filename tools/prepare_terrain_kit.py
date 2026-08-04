"""Split the Meshy 3x3 terrain atlas by loose-island proximity.

The source contains hundreds of disconnected decorative islands per intended asset,
so assigning each island by its center corrupts wide trees and rocks. This version
first joins islands whose three-dimensional bounds overlap. That recovers seven
assets and the road directly; only the adjacent stream/bridge pair needs a final
split along the visible horizontal gap.
"""

from __future__ import annotations

import bpy
import json
import os
import sys
from mathutils import Matrix, Vector


ASSET_GRID = {
    (0, 0): "BroadleafTree",
    (1, 0): "PineTree",
    (2, 0): "DeadStump",
    (0, 1): "RoundedBoulder",
    (1, 1): "JaggedBoulders",
    (2, 1): "RollingHill",
    (0, 2): "RoadTile",
    (1, 2): "StreamTile",
    (2, 2): "BridgeTile",
}

X_CENTERS = (-0.63, 0.0, 0.63)
Y_CENTERS = (0.62, 0.04, -0.57)
AABB_EPSILON = 0.005
STREAM_BRIDGE_CUT_X = 0.315


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


def bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[axis] for point in points) for axis in range(3)))
    maximum = Vector(tuple(max(point[axis] for point in points) for axis in range(3)))
    return minimum, maximum


def group_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    object_bounds = [bounds(obj) for obj in objects]
    minimum = Vector(tuple(min(pair[0][axis] for pair in object_bounds) for axis in range(3)))
    maximum = Vector(tuple(max(pair[1][axis] for pair in object_bounds) for axis in range(3)))
    return minimum, maximum


def bounds_overlap(left: tuple[Vector, Vector], right: tuple[Vector, Vector]) -> bool:
    return all(
        left[1][axis] + AABB_EPSILON >= right[0][axis]
        and right[1][axis] + AABB_EPSILON >= left[0][axis]
        for axis in range(3)
    )


def center_of(obj: bpy.types.Object) -> Vector:
    minimum, maximum = bounds(obj)
    return (minimum + maximum) * 0.5


def nearest_grid_key(center: Vector) -> tuple[int, int]:
    return min(
        ASSET_GRID,
        key=lambda key: (center.x - X_CENTERS[key[0]]) ** 2 + (center.y - Y_CENTERS[key[1]]) ** 2,
    )


def join_objects(name: str, members: list[bpy.types.Object]) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for member in members:
        member.select_set(True)
    bpy.context.view_layer.objects.active = members[0]
    bpy.ops.object.join()
    result = bpy.context.active_object
    result.name = name
    result.data.name = f"{name}Mesh"
    return result


def export_selected(filepath: str) -> None:
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )


def render_preview(assets: dict[str, bpy.types.Object], filepath: str) -> None:
    for key, name in ASSET_GRID.items():
        assets[name].location = Vector(((key[0] - 1) * 1.0, (1 - key[1]) * 1.0, 0.0))

    world = bpy.data.worlds.new("TerrainPreviewWorld") if not bpy.data.worlds else bpy.data.worlds[0]
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.85

    camera_data = bpy.data.cameras.new("TerrainPreviewCamera")
    camera = bpy.data.objects.new("TerrainPreviewCamera", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    camera.location = Vector((0.0, 0.0, 8.0))
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 3.35
    bpy.context.scene.camera = camera

    light_data = bpy.data.lights.new("TerrainPreviewKey", type="AREA")
    light_data.energy = 900.0
    light_data.shape = "DISK"
    light_data.size = 6.0
    light = bpy.data.objects.new("TerrainPreviewKey", light_data)
    bpy.context.scene.collection.objects.link(light)
    light.location = Vector((-2.5, -3.0, 7.0))

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1400
    scene.render.resolution_y = 1400
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.filepath = filepath
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    bpy.ops.render.render(write_still=True)


args = sys.argv[sys.argv.index("--") + 1 :]
if len(args) != 5:
    raise SystemExit(
        "Usage: blender --background --python prepare_terrain_kit.py -- "
        "input.glb combined.glb individual-dir report.json preview.png"
    )
source_path, combined_path, individual_dir, report_path, preview_path = args

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source_path)
source_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if len(source_objects) != 1:
    raise RuntimeError(f"Expected one source mesh, got {len(source_objects)}")

bpy.context.view_layer.objects.active = source_objects[0]
source_objects[0].select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
loose_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
loose_bounds = [bounds(obj) for obj in loose_objects]

union_find = UnionFind(len(loose_objects))
for left in range(len(loose_objects)):
    for right in range(left + 1, len(loose_objects)):
        if bounds_overlap(loose_bounds[left], loose_bounds[right]):
            union_find.union(left, right)

clusters_by_root: dict[int, list[bpy.types.Object]] = {}
for index, obj in enumerate(loose_objects):
    clusters_by_root.setdefault(union_find.find(index), []).append(obj)
clusters = list(clusters_by_root.values())

assignments: dict[str, list[bpy.types.Object]] = {name: [] for name in ASSET_GRID.values()}
cluster_report = []
for cluster in clusters:
    minimum, maximum = group_bounds(cluster)
    center = (minimum + maximum) * 0.5
    size = maximum - minimum
    if center.y < -0.2 and size.x > 0.9:
        left_members = [obj for obj in cluster if center_of(obj).x < STREAM_BRIDGE_CUT_X]
        right_members = [obj for obj in cluster if center_of(obj).x >= STREAM_BRIDGE_CUT_X]
        assignments["StreamTile"].extend(left_members)
        assignments["BridgeTile"].extend(right_members)
        assigned_to = ["StreamTile", "BridgeTile"]
    else:
        asset_name = ASSET_GRID[nearest_grid_key(center)]
        assignments[asset_name].extend(cluster)
        assigned_to = [asset_name]
    cluster_report.append(
        {
            "islands": len(cluster),
            "polygons": sum(len(obj.data.polygons) for obj in cluster),
            "center": [round(value, 6) for value in center],
            "size": [round(value, 6) for value in size],
            "assigned_to": assigned_to,
        }
    )

if len(clusters) != 8:
    raise RuntimeError(f"Expected eight proximity clusters before stream/bridge split, got {len(clusters)}")
if any(not members for members in assignments.values()):
    missing = [name for name, members in assignments.items() if not members]
    raise RuntimeError(f"No geometry assigned to: {', '.join(missing)}")
if sum(len(members) for members in assignments.values()) != len(loose_objects):
    raise RuntimeError("Some loose islands were lost or assigned more than once")

assets: dict[str, bpy.types.Object] = {}
asset_report = []
for key, asset_name in ASSET_GRID.items():
    members = assignments[asset_name]
    asset = join_objects(asset_name, members)
    assets[asset_name] = asset
    minimum, maximum = bounds(asset)
    asset_report.append(
        {
            "name": asset_name,
            "grid": list(key),
            "loose_islands": len(members),
            "vertices": len(asset.data.vertices),
            "polygons": len(asset.data.polygons),
            "bounds": {
                "min": [round(value, 6) for value in minimum],
                "max": [round(value, 6) for value in maximum],
                "size": [round(value, 6) for value in maximum - minimum],
            },
        }
    )

bpy.ops.object.select_all(action="DESELECT")
for asset in assets.values():
    asset.select_set(True)
export_selected(combined_path)

for asset_name, asset in assets.items():
    minimum, maximum = bounds(asset)
    origin = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
    asset.data.transform(Matrix.Translation(-origin))
    asset.matrix_world = Matrix.Identity(4)
    bpy.ops.object.select_all(action="DESELECT")
    asset.select_set(True)
    bpy.context.view_layer.objects.active = asset
    export_selected(os.path.join(individual_dir, f"{asset_name}.glb"))

render_preview(assets, preview_path)

report = {
    "source": source_path,
    "method": "3D AABB-overlap clusters plus isolated stream/bridge X split",
    "aabb_epsilon": AABB_EPSILON,
    "stream_bridge_cut_x": STREAM_BRIDGE_CUT_X,
    "source_loose_islands": len(loose_objects),
    "proximity_clusters": cluster_report,
    "assets": asset_report,
}
os.makedirs(os.path.dirname(report_path), exist_ok=True)
with open(report_path, "w", encoding="utf-8") as handle:
    json.dump(report, handle, indent=2)

print(f"TERRAIN_SPLIT_OK clusters={len(clusters)} assets={len(assets)} islands={len(loose_objects)}")
