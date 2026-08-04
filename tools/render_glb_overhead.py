import bpy
import math
import os
import sys
from mathutils import Vector


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


args = sys.argv[sys.argv.index("--") + 1 :]
source_path, output_path = args
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source_path)

runtime_layout = {
    "BroadleafTree": (-0.72, 0.72),
    "PineTree": (0.0, 0.72),
    "DeadStump": (0.72, 0.72),
    "RoundedBoulder": (-0.72, 0.0),
    "JaggedBoulders": (0.0, 0.0),
    "RollingHill": (0.72, 0.0),
    "RoadTile": (-0.72, -0.72),
    "StreamTile": (0.0, -0.72),
    "BridgeTile": (0.72, -0.72),
}
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if set(runtime_layout).issubset({obj.name for obj in mesh_objects}):
    for obj in mesh_objects:
        if obj.name not in runtime_layout:
            continue
        largest_xy = max(obj.dimensions.x, obj.dimensions.y)
        scale = 0.52 / largest_xy if largest_xy > 0 else 1.0
        obj.scale = (scale, scale, scale)
        obj.location.x, obj.location.y = runtime_layout[obj.name]

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 1200
scene.render.resolution_y = 1200
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = output_path
scene.render.film_transparent = False
scene.world = bpy.data.worlds.new("InspectionWorld")
scene.world.color = (1.0, 1.0, 1.0)

camera_data = bpy.data.cameras.new("InspectionCamera")
camera = bpy.data.objects.new("InspectionCamera", camera_data)
scene.collection.objects.link(camera)
camera.location = (0.0, 0.0, 4.0)
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.25
look_at(camera, (0.0, 0.0, 0.0))
scene.camera = camera

key_data = bpy.data.lights.new("Key", "AREA")
key_data.energy = 900
key_data.shape = "DISK"
key_data.size = 4.0
key = bpy.data.objects.new("Key", key_data)
scene.collection.objects.link(key)
key.location = (-2.5, -2.0, 5.0)
look_at(key, (0.0, 0.0, 0.0))

fill_data = bpy.data.lights.new("Fill", "AREA")
fill_data.energy = 500
fill_data.size = 3.0
fill = bpy.data.objects.new("Fill", fill_data)
scene.collection.objects.link(fill)
fill.location = (2.5, 2.0, 3.0)
look_at(fill, (0.0, 0.0, 0.0))

os.makedirs(os.path.dirname(output_path), exist_ok=True)
bpy.ops.render.render(write_still=True)
