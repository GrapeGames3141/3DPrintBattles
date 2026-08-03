import bpy
import mathutils
import os
import sys


ACTION_NAMES = {
    "falling_down": "Fall",
    "Right_Hand_Sword_Slash": "SwordSlash",
    "Running": "Run",
    "Stand_Up7": "StandUp",
    "Sword_and_Shield_Alert_Turn_Left": "AlertTurnLeft",
    "Walk_Backward_with_Sword_inplace": "WalkBackward",
    "Walking": "Walk",
}


def remove_object(obj):
    data = obj.data
    bpy.data.objects.remove(obj, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def world_bounds(obj):
    points = [obj.matrix_world @ mathutils.Vector(corner) for corner in obj.bound_box]
    mins = [min(point[index] for point in points) for index in range(3)]
    maxs = [max(point[index] for point in points) for index in range(3)]
    return mins, maxs


def apply_decimate(obj, target_faces):
    face_count = len(obj.data.polygons)
    if face_count <= target_faces:
        return
    modifier = obj.modifiers.new(name="RuntimeDecimate", type="DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = target_faces / float(face_count)
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def rigid_bind_shield(obj, target_group_name="LeftHand"):
    """Replace bad auto-weights on the shield's disconnected rigid pieces."""
    mesh = obj.data
    parent = list(range(len(mesh.vertices)))
    sizes = [1] * len(mesh.vertices)

    def find(index):
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index

    def union(left, right):
        left_root = find(left)
        right_root = find(right)
        if left_root == right_root:
            return
        if sizes[left_root] < sizes[right_root]:
            left_root, right_root = right_root, left_root
        parent[right_root] = left_root
        sizes[left_root] += sizes[right_root]

    for edge in mesh.edges:
        union(edge.vertices[0], edge.vertices[1])

    components = {}
    for vertex in mesh.vertices:
        components.setdefault(find(vertex.index), []).append(vertex.index)

    shield_indices = []
    for indices in components.values():
        points = [obj.matrix_world @ mesh.vertices[index].co for index in indices]
        center_x = (min(point.x for point in points) + max(point.x for point in points)) * 0.5
        center_z = (min(point.z for point in points) + max(point.z for point in points)) * 0.5
        if center_x <= 0.28 or not 0.33 < center_z < 0.82:
            continue

        totals = {}
        for index in indices:
            for assignment in mesh.vertices[index].groups:
                name = obj.vertex_groups[assignment.group].name
                totals[name] = totals.get(name, 0.0) + assignment.weight
        weight_total = sum(totals.values()) or 1.0
        has_hand_chain = any(totals.get(name, 0.0) > 0.0 for name in ("LeftHand", "LeftForeArm", "LeftArm"))
        stray_share = (totals.get("LeftUpLeg", 0.0) + totals.get("Spine01", 0.0)) / weight_total
        if has_hand_chain and stray_share > 0.005:
            shield_indices.extend(indices)

    if not shield_indices:
        raise RuntimeError("Shield rigid-bind selection found no vertices")
    for group in obj.vertex_groups:
        group.remove(shield_indices)
    target_group = obj.vertex_groups.get(target_group_name)
    if target_group is None:
        target_group = obj.vertex_groups.new(name=target_group_name)
    target_group.add(shield_indices, 1.0, "REPLACE")
    print(f"Rigid-bound {len(shield_indices)} shield vertices to {target_group_name}")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 2:
        raise SystemExit("Expected: merged_animation.glb output.glb")
    source_path, output_path = args

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_path)

    armature = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
    mesh = next(
        obj for obj in bpy.context.scene.objects
        if obj.type == "MESH" and obj.name.casefold() != "icosphere"
    )

    # Meshy ships a bone-display helper as real renderable geometry. It is useful
    # in a DCC viewport but should never appear in the game export.
    for pose_bone in armature.pose.bones:
        pose_bone.custom_shape = None
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj != mesh:
            remove_object(obj)

    armature.name = "IronboundGoblinRig"
    armature.data.name = "IronboundGoblinSkeleton"
    mesh.name = "IronboundGoblinSkinnedMesh"
    mesh.data.name = "IronboundGoblinSkinnedMeshData"

    for action in bpy.data.actions:
        action.name = ACTION_NAMES.get(action.name, action.name)
        action.use_fake_user = True

    rigid_bind_shield(mesh)
    apply_decimate(mesh, 90000)

    root = bpy.data.objects.new("IronboundGoblinAnimated", None)
    bpy.context.scene.collection.objects.link(root)
    armature.parent = root

    mins, maxs = world_bounds(mesh)
    root.location.x = -((mins[0] + maxs[0]) * 0.5)
    root.location.y = -((mins[1] + maxs[1]) * 0.5)
    root.location.z = -mins[2]

    bpy.ops.object.select_all(action="DESELECT")
    for obj in (root, armature, mesh):
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
