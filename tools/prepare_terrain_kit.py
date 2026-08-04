import bpy
import json
import math
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


def bounds(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    mins = Vector(tuple(min(point[i] for point in points) for i in range(3)))
    maxs = Vector(tuple(max(point[i] for point in points) for i in range(3)))
    return mins, maxs


def closest_index(value, centers):
    return min(range(len(centers)), key=lambda index: abs(value - centers[index]))


args = sys.argv[sys.argv.index("--") + 1 :]
if len(args) != 3:
    raise SystemExit("Usage: blender --background --python prepare_terrain_kit.py -- input.glb output.glb report.json")
source_path, output_path, report_path = args

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

groups = {key: [] for key in ASSET_GRID}
for obj in [item for item in bpy.context.scene.objects if item.type == "MESH"]:
    minimum, maximum = bounds(obj)
    center = (minimum + maximum) * 0.5
    column = closest_index(center.x, X_CENTERS)
    row = closest_index(center.y, Y_CENTERS)
    groups[(column, row)].append(obj)

report = []
for key, asset_name in ASSET_GRID.items():
    members = groups[key]
    if not members:
        raise RuntimeError(f"No geometry assigned to {asset_name}")
    bpy.ops.object.select_all(action="DESELECT")
    for member in members:
        member.select_set(True)
    bpy.context.view_layer.objects.active = members[0]
    bpy.ops.object.join()
    asset = bpy.context.active_object
    asset.name = asset_name
    asset.data.name = f"{asset_name}Mesh"

    minimum, maximum = bounds(asset)
    center_xy = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
    asset.data.transform(Matrix.Translation(-center_xy))
    asset.matrix_world = Matrix.Identity(4)

    before = len(asset.data.polygons)
    modifier = asset.modifiers.new(name="RuntimeDecimate", type="DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = 0.34
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = asset
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    after = len(asset.data.polygons)
    report.append({"name": asset_name, "loose_parts": len(members), "polygons_before": before, "polygons_after": after})

bpy.ops.object.select_all(action="SELECT")
os.makedirs(os.path.dirname(output_path), exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=output_path,
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_materials="EXPORT",
    export_image_format="AUTO",
)
os.makedirs(os.path.dirname(report_path), exist_ok=True)
with open(report_path, "w", encoding="utf-8") as handle:
    json.dump(report, handle, indent=2)
