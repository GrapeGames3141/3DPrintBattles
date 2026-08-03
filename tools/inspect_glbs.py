import bpy
import json
import math
import os
import sys


def vec(values):
    return [round(float(value), 6) for value in values]


def inspect(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.gltf(filepath=path)
    objects = []
    world_points = []

    for obj in bpy.context.scene.objects:
        item = {
            "name": obj.name,
            "type": obj.type,
            "parent": obj.parent.name if obj.parent else None,
            "location": vec(obj.location),
            "rotation_euler": vec(obj.rotation_euler),
            "scale": vec(obj.scale),
        }
        if obj.type == "MESH":
            item["vertices"] = len(obj.data.vertices)
            item["polygons"] = len(obj.data.polygons)
            item["materials"] = [slot.material.name if slot.material else None for slot in obj.material_slots]
            for corner in obj.bound_box:
                world_points.append(obj.matrix_world @ mathutils.Vector(corner))
        objects.append(item)

    bounds = None
    if world_points:
        mins = [min(point[index] for point in world_points) for index in range(3)]
        maxs = [max(point[index] for point in world_points) for index in range(3)]
        bounds = {
            "min": vec(mins),
            "max": vec(maxs),
            "size": vec([maxs[index] - mins[index] for index in range(3)]),
            "center": vec([(mins[index] + maxs[index]) * 0.5 for index in range(3)]),
        }

    materials = []
    for material in bpy.data.materials:
        textures = []
        if material.use_nodes and material.node_tree:
            for node in material.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    textures.append({
                        "name": node.image.name,
                        "size": list(node.image.size),
                        "file_format": node.image.file_format,
                    })
        materials.append({"name": material.name, "textures": textures})

    actions = []
    for action in bpy.data.actions:
        actions.append({
            "name": action.name,
            "frame_range": vec(action.frame_range),
            "channels": len(action.fcurves),
        })

    return {
        "path": path,
        "import_result": sorted(str(value) for value in result),
        "bounds": bounds,
        "objects": objects,
        "materials": materials,
        "actions": actions,
    }


if __name__ == "__main__":
    import mathutils

    if "--" not in sys.argv:
        raise SystemExit("Pass GLB paths and output JSON after --")
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) < 2:
        raise SystemExit("Usage: blender --background --python inspect_glbs.py -- input.glb [...] output.json")
    output_path = args[-1]
    reports = [inspect(path) for path in args[:-1]]
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as handle:
        json.dump(reports, handle, indent=2)
