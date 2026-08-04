"""Create a centered, decimated, texture-reduced runtime terrain library."""

from __future__ import annotations

import bpy
import json
import math
import os
import sys
from mathutils import Matrix, Vector


TARGET_FACES = {
    "BroadleafTree": 18000,
    "PineTree": 14000,
    "DeadStump": 12000,
    "RoundedBoulder": 5000,
    "JaggedBoulders": 7000,
    "RollingHill": 4000,
    "RoadTile": 2500,
    "StreamTile": 3000,
    "BridgeTile": 9000,
}
MAX_TEXTURE_SIZE = 1024


def select_only(objects: list[bpy.types.Object]) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    if objects:
        bpy.context.view_layer.objects.active = objects[0]


def local_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [Vector(corner) for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[axis] for point in points) for axis in range(3)))
    maximum = Vector(tuple(max(point[axis] for point in points) for axis in range(3)))
    return minimum, maximum


def canonical_name(name: str) -> str | None:
    for expected in TARGET_FACES:
        if name == expected or name.startswith(f"{expected}."):
            return expected
    return None


def center_at_ground(obj: bpy.types.Object) -> None:
    select_only([obj])
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    minimum, maximum = local_bounds(obj)
    origin = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
    obj.data.transform(Matrix.Translation(-origin))
    obj.location = Vector((0.0, 0.0, 0.0))


def decimate(obj: bpy.types.Object, target_faces: int) -> None:
    source_faces = len(obj.data.polygons)
    if source_faces <= target_faces:
        return
    modifier = obj.modifiers.new(name="RuntimeDecimate", type="DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = max(0.001, min(1.0, target_faces / float(source_faces)))
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def reduce_textures() -> list[dict]:
    report = []
    for image in bpy.data.images:
        if image.size[0] <= 0 or image.size[1] <= 0:
            continue
        before = [int(image.size[0]), int(image.size[1])]
        longest = max(before)
        if longest > MAX_TEXTURE_SIZE:
            ratio = MAX_TEXTURE_SIZE / float(longest)
            image.scale(max(1, round(before[0] * ratio)), max(1, round(before[1] * ratio)))
        report.append({"name": image.name, "before": before, "after": [int(image.size[0]), int(image.size[1])]})
    return report


def render_preview(objects: list[bpy.types.Object], filepath: str) -> None:
    layout = {
        "BroadleafTree": (-2.3, 2.3),
        "PineTree": (0.0, 2.3),
        "DeadStump": (2.3, 2.3),
        "RoundedBoulder": (-2.3, 0.0),
        "JaggedBoulders": (0.0, 0.0),
        "RollingHill": (2.3, 0.0),
        "RoadTile": (-2.3, -2.3),
        "StreamTile": (0.0, -2.3),
        "BridgeTile": (2.3, -2.3),
    }
    for obj in objects:
        x, y = layout[obj.name]
        obj.location = Vector((x, y, 0.0))

    world = bpy.data.worlds.new("RuntimePreviewWorld") if not bpy.data.worlds else bpy.data.worlds[0]
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8

    camera_data = bpy.data.cameras.new("RuntimePreviewCamera")
    camera = bpy.data.objects.new("RuntimePreviewCamera", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    camera.location = Vector((0.0, -8.6, 7.6))
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 8.3
    direction = Vector((0.0, 0.0, 0.2)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = camera

    light_data = bpy.data.lights.new("RuntimePreviewKey", type="AREA")
    light_data.energy = 1100.0
    light_data.size = 6.0
    light = bpy.data.objects.new("RuntimePreviewKey", light_data)
    bpy.context.scene.collection.objects.link(light)
    light.location = Vector((-3.5, -4.0, 8.0))

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

    for obj in objects:
        obj.location = Vector((0.0, 0.0, 0.0))


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 4:
        raise SystemExit("Expected: combined_source.glb runtime_output.glb report.json preview.png")
    source_path, output_path, report_path, preview_path = args

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_path)
    source_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    objects_by_name: dict[str, bpy.types.Object] = {}
    for obj in source_meshes:
        name = canonical_name(obj.name)
        if name is None:
            raise RuntimeError(f"Unexpected terrain mesh {obj.name}")
        if name in objects_by_name:
            raise RuntimeError(f"Duplicate terrain mesh {name}")
        obj.name = name
        obj.data.name = f"{name}Mesh"
        objects_by_name[name] = obj
    if set(objects_by_name) != set(TARGET_FACES):
        raise RuntimeError(f"Terrain library mismatch: {sorted(objects_by_name)}")

    asset_report = []
    for name in TARGET_FACES:
        obj = objects_by_name[name]
        source_faces = len(obj.data.polygons)
        center_at_ground(obj)
        # Meshy's 3x3 presentation atlas placed every square tile on a 45-degree
        # diamond. Align the reusable runtime meshes to the combat grid once here
        # so non-uniform road/river fitting does not create sheared chevrons.
        obj.data.transform(Matrix.Rotation(math.radians(-45.0), 4, "Z"))
        decimate(obj, TARGET_FACES[name])
        minimum, maximum = local_bounds(obj)
        asset_report.append(
            {
                "name": name,
                "source_faces": source_faces,
                "runtime_faces": len(obj.data.polygons),
                "bounds": {
                    "min": [round(value, 6) for value in minimum],
                    "max": [round(value, 6) for value in maximum],
                    "size": [round(value, 6) for value in maximum - minimum],
                },
            }
        )

    texture_report = reduce_textures()
    prepared = [objects_by_name[name] for name in TARGET_FACES]
    render_preview(prepared, preview_path)
    select_only(prepared)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=False,
        export_yup=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )

    report = {
        "source": source_path,
        "output": output_path,
        "output_bytes": os.path.getsize(output_path),
        "target_faces": TARGET_FACES,
        "source_total_faces": sum(item["source_faces"] for item in asset_report),
        "runtime_total_faces": sum(item["runtime_faces"] for item in asset_report),
        "texture_limit": MAX_TEXTURE_SIZE,
        "textures": texture_report,
        "assets": asset_report,
    }
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    print(
        "TERRAIN_RUNTIME_OK assets=%d faces=%d bytes=%d"
        % (len(prepared), report["runtime_total_faces"], report["output_bytes"])
    )


if __name__ == "__main__":
    main()
