import bpy
import json
import sys


source_path, report_path = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source_path)
armature = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
report = []
for bone in armature.data.bones:
    if any(token in bone.name.casefold() for token in ("hand", "arm", "shoulder")):
        head = armature.matrix_world @ bone.head_local
        tail = armature.matrix_world @ bone.tail_local
        report.append({
            "name": bone.name,
            "head": [round(value, 6) for value in head],
            "tail": [round(value, 6) for value in tail],
        })
with open(report_path, "w", encoding="utf-8") as handle:
    json.dump(report, handle, indent=2)
