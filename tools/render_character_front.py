import bpy
import os
import sys
from mathutils import Vector


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


source_path, output_path = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source_path)

for obj in bpy.context.scene.objects:
    if obj.type == "MESH" and ("icosphere" in obj.name.lower() or "helper" in obj.name.lower()):
        obj.hide_render = True

meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.hide_render]
mins = Vector((1e9, 1e9, 1e9))
maxs = Vector((-1e9, -1e9, -1e9))
for obj in meshes:
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        mins.x, mins.y, mins.z = min(mins.x, point.x), min(mins.y, point.y), min(mins.z, point.z)
        maxs.x, maxs.y, maxs.z = max(maxs.x, point.x), max(maxs.y, point.y), max(maxs.z, point.z)
center = (mins + maxs) * 0.5
height = maxs.z - mins.z

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 900
scene.render.resolution_y = 1200
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = output_path
scene.render.film_transparent = False
scene.world = bpy.data.worlds.new("InspectionWorld")
scene.world.color = (0.96, 0.96, 0.96)

camera_data = bpy.data.cameras.new("InspectionCamera")
camera = bpy.data.objects.new("InspectionCamera", camera_data)
scene.collection.objects.link(camera)
camera.location = (center.x, mins.y - max(height * 2.0, 4.0), center.z)
camera_data.type = "ORTHO"
camera_data.ortho_scale = height * 1.18
look_at(camera, center)
scene.camera = camera

for name, location, energy, size in [
    ("Key", (-3.0, -4.0, maxs.z + 2.0), 1100, 4.0),
    ("Fill", (3.0, -2.0, center.z), 650, 3.0),
    ("Rim", (0.0, 2.0, maxs.z + 1.0), 850, 3.0),
]:
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    light = bpy.data.objects.new(name, data)
    scene.collection.objects.link(light)
    light.location = location
    look_at(light, center)

os.makedirs(os.path.dirname(output_path), exist_ok=True)
bpy.ops.render.render(write_still=True)
