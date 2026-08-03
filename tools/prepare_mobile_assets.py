import bpy
import math
import mathutils
import os
import sys


BASE_CLUSTERS = {
    "BaseWood": (-0.75, 0.70),
    "BaseStone": (0.00, 0.70),
    "BaseBronze": (0.75, 0.70),
    "BaseSteel": (-0.75, 0.00),
    "BaseCarbon": (0.00, 0.00),
    "BaseCrystal": (0.75, 0.00),
    "SourceCrest": (0.00, -0.75),
}


def select_only(objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    if objects:
        bpy.context.view_layer.objects.active = objects[0]


def world_bounds(obj):
    points = [obj.matrix_world @ mathutils.Vector(corner) for corner in obj.bound_box]
    mins = [min(point[index] for point in points) for index in range(3)]
    maxs = [max(point[index] for point in points) for index in range(3)]
    return mins, maxs


def apply_decimate(obj, target_faces):
    face_count = len(obj.data.polygons)
    if face_count <= target_faces:
        return
    modifier = obj.modifiers.new(name="MobileDecimate", type="DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = max(0.01, min(1.0, target_faces / float(face_count)))
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def prepare_bases(source_path, output_path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_path)
    source_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(source_objects) != 1:
        raise RuntimeError(f"Expected one base source mesh, got {len(source_objects)}")

    select_only(source_objects)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")

    groups = {name: [] for name in BASE_CLUSTERS}
    for obj in [item for item in bpy.context.scene.objects if item.type == "MESH"]:
        mins, maxs = world_bounds(obj)
        center_x = (mins[0] + maxs[0]) * 0.5
        center_y = (mins[1] + maxs[1]) * 0.5
        nearest_name = min(
            BASE_CLUSTERS,
            key=lambda name: math.dist((center_x, center_y), BASE_CLUSTERS[name]),
        )
        groups[nearest_name].append(obj)

    prepared = []
    for name, objects in groups.items():
        if not objects:
            raise RuntimeError(f"No geometry assigned to {name}")
        select_only(objects)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        obj = bpy.context.view_layer.objects.active
        obj.name = name
        obj.data.name = f"{name}Mesh"
        bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
        obj.location = (0.0, 0.0, 0.0)
        apply_decimate(obj, 18000 if name != "SourceCrest" else 10000)
        prepared.append(obj)

    select_only(prepared)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=False,
        export_yup=True,
    )


def prepare_goblin(source_path, output_path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_path)
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(mesh_objects) != 1:
        raise RuntimeError(f"Expected one goblin mesh, got {len(mesh_objects)}")
    obj = mesh_objects[0]
    obj.name = "IronboundGoblin"
    obj.data.name = "IronboundGoblinMesh"
    apply_decimate(obj, 85000)

    mins, maxs = world_bounds(obj)
    center_x = (mins[0] + maxs[0]) * 0.5
    center_y = (mins[1] + maxs[1]) * 0.5
    min_z = mins[2]
    for vertex in obj.data.vertices:
        vertex.co.x -= center_x
        vertex.co.y -= center_y
        vertex.co.z -= min_z
    obj.location = (0.0, 0.0, 0.0)

    select_only([obj])
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=True,
        export_yup=True,
    )


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 4:
        raise SystemExit("Expected: goblin_source base_source goblin_output base_output")
    prepare_goblin(args[0], args[2])
    prepare_bases(args[1], args[3])
