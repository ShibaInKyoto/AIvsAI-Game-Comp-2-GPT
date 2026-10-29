"""Original Night Service locomotive. Blender: --background --python this_file.py.

Blender front is -Y, exported as Godot +Z. The wheels meet the track at Y=0
in Godot. All details are joined into a handful of reusable material surfaces.
"""
from pathlib import Path
import math
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from modeling import clear, material, box, cylinder, sphere, tube_between, export

clear()
enamel = material('Night Service deep teal enamel', (.045, .19, .20), .5, .28)
brass = material('Night Service champagne brass', (.72, .47, .21), .72, .3)
iron = material('Night Service graphite iron', (.027, .037, .048), .6, .45)
roof = material('Night Service blue-black roof', (.035, .065, .084), .35, .4)
glass = material('Night Service warm windows', (.9, .47, .15), .1, .3)
lamp = material('Night Service headlamp', (1, .81, .48), .0, .3)
for mat, color, strength in [(glass, (1, .50, .15, 1), .7), (lamp, (1, .78, .38, 1), 2.0)]:
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Emission Color'].default_value = color
    shader.inputs['Emission Strength'].default_value = strength


def longitudinal(pos, radius, length, mat, vertices=32):
    obj = cylinder(pos, radius, length, mat, vertices)
    obj.rotation_euler.x = math.pi / 2
    return obj


# Long sweeping boiler, prow and a rising enclosed cab.
box((0, .2, .95), (2.6, 10.6, .35), iron, .08)
longitudinal((0, -1.05, 2.28), 1.13, 6.0, enamel)
sphere((0, -4.05, 2.28), (1.13, .72, 1.13), enamel)
for y in [-3.65, -2.0, .0, 1.55]:
    longitudinal((0, y, 2.28), 1.155, .09, brass)
box((0, 2.78, 2.34), (2.64, 2.65, 2.6), enamel, .14)
box((0, 2.78, 3.72), (2.9, 2.95, .26), roof, .12)
box((0, 2.78, 3.91), (2.25, 2.8, .12), brass, .035)
for side in [-1, 1]:
    # Inlaid brass speed lines become a fan across the engine's flank.
    for height in [1.30, 1.47, 1.64]:
        box((side * 1.17, -.95, height), (.055, 7.3, .045), brass, .01)
    for y in [2.05, 3.15]:
        box((side * 1.335, y, 2.85), (.035, .82, 1.0), brass, .03)
        box((side * 1.36, y, 2.85), (.025, .68, .85), glass, .025)
        box((side * 1.38, y, 2.85), (.02, .035, .85), brass, .005)
    tube_between((side * 1.3, -3.45, 2.05), (side * 1.3, 1.5, 2.05), .032, brass)
    for y in [-3.1, -.8, 1.25]:
        tube_between((side * 1.1, y, 1.95), (side * 1.3, y, 2.05), .022, brass)
    for step in range(3):
        box((side * (1.3 + .13 * step), 3.8, .9 - .21 * step), (.3, .7, .07), brass, .015)

# Chimney, steam dome and whistle give the silhouette a distinctive profile.
cylinder((0, -2.75, 3.57), .30, .75, roof, 24, radius_top=.40)
cylinder((0, -2.75, 3.97), .46, .12, brass)
sphere((0, -.25, 3.48), (.48, .6, .4), brass)
cylinder((.5, 1.4, 3.72), .09, .6, brass, 12)
cylinder((.5, 1.4, 4.04), .14, .08, brass, 16)

# Deco shield and lamp: concentric brass rings with a winged nose ornament.
longitudinal((0, -4.65, 2.28), .67, .12, brass)
longitudinal((0, -4.74, 2.28), .57, .10, roof)
longitudinal((0, -4.82, 2.5), .26, .15, brass)
longitudinal((0, -4.91, 2.5), .20, .025, lamp)
for side in [-1, 1]:
    for height in [1.86, 2.02, 2.18]:
        tube_between((0, -4.86, height), (side * .46, -4.79, height + .15), .025, brass)
    longitudinal((side * .96, -4.7, 1.33), .13, .22, brass, 16)
    longitudinal((side * .96, -4.83, 1.33), .09, .02, lamp, 16)
    tube_between((side * 1.4, -4.4, .85), (0, -5.65, .22), .07, brass)
    for i in range(5):
        x = side * (.2 + i * .25)
        tube_between((x, -4.42, .83), (x * .75, -5.65 + abs(x) * .45, .23), .028, iron)

# Three large driving axles, small leading/trailing wheels, and coupling rods.
for side in [-1, 1]:
    for y, radius in [(-3.85, .45), (-2.4, .78), (-.65, .78), (1.1, .78), (3.25, .55)]:
        wheel = cylinder((side * 1.2, y, radius), radius, .22, iron, 32)
        wheel.rotation_euler.y = math.pi / 2
        rim = cylinder((side * 1.32, y, radius), radius * .82, .05, brass, 32)
        rim.rotation_euler.y = math.pi / 2
        inset = cylinder((side * 1.35, y, radius), radius * .67, .055, roof, 24)
        inset.rotation_euler.y = math.pi / 2
        for spoke in range(8):
            angle = spoke * math.tau / 8
            tube_between((side * 1.39, y, radius), (side * 1.39, y + math.cos(angle) * radius * .65, radius + math.sin(angle) * radius * .65), .024, brass)
        hub = cylinder((side * 1.42, y, radius), .10, .10, brass, 16)
        hub.rotation_euler.y = math.pi / 2
    tube_between((side * 1.48, -2.4, .62), (side * 1.48, 1.1, .62), .07, brass)

# A compact matching tender; the carriage rake begins beyond it.
box((0, 6.3, .95), (2.65, 3.65, .28), iron, .05)
box((0, 6.3, 1.85), (2.7, 3.5, 1.7), enamel, .12)
box((0, 6.3, 2.73), (2.82, 3.62, .12), brass, .035)
box((0, 6.3, 2.82), (2.35, 3.1, .18), roof, .07)
for side in [-1, 1]:
    for height in [1.55, 1.75, 1.95]:
        box((side * 1.36, 6.3, height), (.04, 3.25, .045), brass, .01)
    for y in [5.25, 7.35]:
        wheel = cylinder((side * 1.2, y, .55), .55, .22, iron, 24)
        wheel.rotation_euler.y = math.pi / 2
        rim = cylinder((side * 1.33, y, .55), .38, .04, brass, 24)
        rim.rotation_euler.y = math.pi / 2
box((0, 8.3, .8), (.35, .6, .2), iron)
export('locomotive')
