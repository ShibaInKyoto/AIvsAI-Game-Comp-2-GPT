"""Folded foliage, shared by the prop generator or built independently with Blender."""
from pathlib import Path
import sys
import math
import random
import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from modeling import clear, cylinder, finish, export, TEAL, GOLD, SOIL, LEAF, LEAF_LIGHT


def leaf(start, end, width, surface):
    start, end = Vector(start), Vector(end)
    direction = end - start
    across = Vector((-direction.y, direction.x, 0)).normalized() * width
    middle = start.lerp(end, .52)
    ridge = middle + Vector((0, 0, .025))
    mesh = bpy.data.meshes.new('Folded leaflet')
    mesh.from_pydata([start, middle + across, end, middle - across, ridge], [],
                     [(0, 4, 1), (1, 4, 2), (2, 4, 3), (3, 4, 0)])
    mesh.update()
    obj = bpy.data.objects.new('Folded leaflet', mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(surface)


def stem(points):
    path = bpy.data.curves.new('Fern stem', 'CURVE')
    path.dimensions = '3D'
    path.resolution_u = 1
    path.bevel_depth = .008
    path.bevel_resolution = 0
    spline = path.splines.new('POLY')
    spline.points.add(len(points) - 1)
    for point, value in zip(spline.points, points):
        point.co = (*value, 1)
    obj = bpy.data.objects.new('Fern stem', path)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    finish(bpy.context.object, LEAF)


def build_fern():
    clear()
    cylinder((0, 0, .26), .30, .5, TEAL, 32, radius_top=.39)
    cylinder((0, 0, .5), .40, .06, GOLD, 32)
    cylinder((0, 0, .53), .34, .018, SOIL, 24)
    cylinder((0, 0, .07), .33, .06, GOLD, 24)
    for frond in range(13):
        angle = frond * math.tau / 13
        spread = .38 + .18 * random.random()
        height = .7 + .5 * random.random()
        points = []
        for step in range(7):
            t = step / 6
            radius = spread * t
            point = (math.cos(angle) * radius, math.sin(angle) * radius,
                     .54 + height * math.sin(t * 1.8))
            points.append(point)
            if 0 < step < 6:
                for side in [-1, 1]:
                    direction = angle + side * 1.1
                    length = .24 * (1 - .5 * t)
                    end = (point[0] + math.cos(direction) * length,
                           point[1] + math.sin(direction) * length, point[2] + .05)
                    leaf(point, end, .075 * (1 - .5 * t), LEAF_LIGHT if frond % 3 == 0 else LEAF)
        stem(points)
    export('winter_fern')


if __name__ == '__main__':
    build_fern()
