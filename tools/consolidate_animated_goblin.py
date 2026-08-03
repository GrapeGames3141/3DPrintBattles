import bpy
import mathutils
import os
import sys


CLIPS = [
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_falling_down_withSkin.glb", "Fall"),
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_Right_Hand_Sword_Slash_withSkin.glb", "SwordSlash"),
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_Running_withSkin.glb", "Run"),
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_Stand_Up7_withSkin.glb", "StandUp"),
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_Sword_and_Shield_Alert_Turn_Left_withSkin.glb", "AlertTurnLeft"),
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_Walk_Backward_with_Sword_inplace_withSkin.glb", "WalkBackward"),
    ("Meshy_AI_Ironbound_Goblin_biped_Animation_Walking_withSkin.glb", "Walk"),
]


def remove_object(obj):
    data = obj.data
    bpy.data.objects.remove(obj, do_unlink=True)
    if data is None or data.users != 0:
        return
    if isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)
    elif isinstance(data, bpy.types.Armature):
        bpy.data.armatures.remove(data)


def apply_decimate(obj, target_faces):
    if len(obj.data.polygons) <= target_faces:
        return
    modifier = obj.modifiers.new(name="WindowsRuntimeDecimate", type="DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = target_faces / float(len(obj.data.polygons))
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 2:
        raise SystemExit("Expected: extracted_animation_directory output.glb")
    source_dir, output_path = args
    character_path = os.path.join(source_dir, "Meshy_AI_Ironbound_Goblin_biped_Character_output.glb")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=character_path)
    master_armature = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
    master_mesh = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj.name != "Icosphere")
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj.name == "Icosphere":
            remove_object(obj)

    master_armature.name = "IronboundGoblinRig"
    master_armature.data.name = "IronboundGoblinSkeleton"
    master_mesh.name = "IronboundGoblinSkinnedMesh"
    master_mesh.data.name = "IronboundGoblinSkinnedMeshData"
    master_bones = tuple(bone.name for bone in master_armature.data.bones)

    if master_armature.animation_data and master_armature.animation_data.action:
        idle_action = master_armature.animation_data.action
        idle_action.name = "IdlePose"
        idle_action.use_fake_user = True

    for filename, friendly_name in CLIPS:
        before_objects = set(bpy.data.objects)
        before_actions = set(bpy.data.actions)
        bpy.ops.import_scene.gltf(filepath=os.path.join(source_dir, filename))
        imported_objects = [obj for obj in bpy.data.objects if obj not in before_objects]
        imported_armature = next(obj for obj in imported_objects if obj.type == "ARMATURE")
        imported_bones = tuple(bone.name for bone in imported_armature.data.bones)
        if imported_bones != master_bones:
            raise RuntimeError(f"Skeleton mismatch in {filename}")
        imported_actions = [action for action in bpy.data.actions if action not in before_actions]
        if len(imported_actions) != 1:
            raise RuntimeError(f"Expected one action in {filename}, found {len(imported_actions)}")
        action = imported_actions[0]
        action.name = friendly_name
        action.use_fake_user = True
        for obj in imported_objects:
            remove_object(obj)

    apply_decimate(master_mesh, 90000)

    root = bpy.data.objects.new("IronboundGoblinAnimated", None)
    bpy.context.scene.collection.objects.link(root)
    master_armature.parent = root

    world_points = [master_mesh.matrix_world @ mathutils.Vector(corner) for corner in master_mesh.bound_box]
    min_z = min(point.z for point in world_points)
    root.location.z = -min_z

    master_armature.animation_data_create()
    master_armature.animation_data.action = bpy.data.actions.get("IdlePose")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in (root, master_armature, master_mesh):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_anim_slide_to_zero=True,
        export_yup=True,
    )
