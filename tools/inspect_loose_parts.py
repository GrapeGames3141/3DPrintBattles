import bpy
import json
import os
import sys


def bounds_for(obj):
    points = [obj.matrix_world @ mathutils.Vector(corner) for corner in obj.bound_box]
    mins = [min(point[index] for point in points) for index in range(3)]
    maxs = [max(point[index] for point in points) for index in range(3)]
    return {
        "min": [round(value, 6) for value in mins],
        "max": [round(value, 6) for value in maxs],
        "size": [round(maxs[index] - mins[index], 6) for index in range(3)],
        "center": [round((mins[index] + maxs[index]) * 0.5, 6) for index in range(3)],
    }


if __name__ == "__main__":
    import mathutils

    args = sys.argv[sys.argv.index("--") + 1 :]
    source_path, output_path = args
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_path)
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(mesh_objects) != 1:
        raise RuntimeError(f"Expected one mesh, got {len(mesh_objects)}")

    bpy.context.view_layer.objects.active = mesh_objects[0]
    mesh_objects[0].select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")

    parts = []
    for index, obj in enumerate(sorted((obj for obj in bpy.context.scene.objects if obj.type == "MESH"), key=lambda item: item.name)):
        parts.append({
            "index": index,
            "name": obj.name,
            "vertices": len(obj.data.vertices),
            "polygons": len(obj.data.polygons),
            "bounds": bounds_for(obj),
        })

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as handle:
        json.dump(parts, handle, indent=2)
