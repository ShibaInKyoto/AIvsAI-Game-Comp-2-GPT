"""Shared Blender geometry helpers for original props and relics.
Models are exported as joined meshes with bevels applied and reusable material surfaces.
"""
from pathlib import Path
import math
import random
import bpy
from mathutils import Vector

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'models'
OUT.mkdir(parents=True, exist_ok=True)
random.seed(1893)


def material(name, color, metallic=0, roughness=.5):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    node = m.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Metallic'].default_value = metallic
    node.inputs['Roughness'].default_value = roughness
    return m


GOLD = material('Aged brass', (.55, .36, .14), .75, .3)
WOOD = material('Polished walnut', (.13, .065, .055), 0, .35)
VELVET = material('Oxblood velvet', (.23, .055, .09), 0, .86)
LEATHER = material('Chestnut leather', (.24, .11, .065), 0, .65)
IVORY = material('Porcelain and linen', (.78, .73, .59), 0, .56)
TEAL = material('Patinated enamel', (.075, .24, .24), .3, .4)
LEAF = material('Winter fern', (.09, .26, .19), 0, .75)
LEAF_LIGHT = material('New growth', (.19, .37, .24), 0, .75)
SOIL = material('Earth', (.045, .03, .025), 0, 1)
GLASS = material('Midnight lens', (.08, .30, .43), .7, .12)
BLACK = material('Iron', (.025, .03, .04), .6, .4)
PAGE = material('Aged paper', (.62, .52, .35), 0, .8)
BOOKS = [material('Book cloth ' + str(i), c, 0, .8) for i, c in enumerate([(.23,.08,.11),(.08,.22,.21),(.31,.24,.12),(.12,.13,.23)])]


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def finish(obj, mat, bevel=0, smooth=False):
    obj.data.materials.append(mat)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Soft manufactured edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        normal = obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
        bpy.ops.object.modifier_apply(modifier=normal.name)
    if smooth:
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    return obj


def box(pos, size, mat, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.scale = size
    return finish(obj, mat, bevel)


def cylinder(pos, radius, depth, mat, vertices=24, radius_top=None):
    if radius_top is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=pos)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius_top, depth=depth, location=pos)
    return finish(bpy.context.object, mat, .009)


def sphere(pos, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1, location=pos)
    obj = bpy.context.object
    obj.scale = scale
    return finish(obj, mat, smooth=True)


def tube_between(start, end, radius, mat):
    a, b = Vector(start), Vector(end)
    obj = cylinder((a+b)/2, radius, (b-a).length, mat, 12)
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = (b-a).to_track_quat('Z', 'Y')
    return obj


def export(name):
    # Blender Z-up becomes glTF Y-up. Front is Blender -Y / Godot +Z.
    bpy.ops.object.select_all(action='DESELECT')
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
    print('MODELED', name, 'vertices', len(obj.data.vertices), flush=True)


