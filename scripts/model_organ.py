"""Original art-deco pipe organ. Blender 4.3; front is Blender -Y / Godot +Z."""
from pathlib import Path
from functools import partial
import math
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from modeling import clear, finish, box as make_box, cylinder as make_cylinder, sphere, tube_between as make_tube, export
from modeling import WOOD, GOLD, VELVET, IVORY, BLACK, TEAL

clear()
# Tiny trim and keys need a highlighted edge, not three roundover subdivisions.
box = partial(make_box, bevel_segments=1)
cylinder = partial(make_cylinder, bevel_segments=1)
tube_between = partial(make_tube, bevel_segments=1)


def hollow_pipe(x, height):
    segments = 20
    bottom = 1.43
    vertices = []
    for radius, z in [(.065, bottom), (.065, bottom + height),
                      (.049, bottom + height), (.049, bottom)]:
        for index in range(segments):
            angle = math.tau * index / segments
            vertices.append((x + math.cos(angle) * radius,
                             .17 + math.sin(angle) * radius, z))
    faces = []
    for ring in range(3):
        for index in range(segments):
            nxt = (index + 1) % segments
            faces.append((ring * segments + index, ring * segments + nxt,
                          (ring + 1) * segments + nxt, (ring + 1) * segments + index))
    mesh = bpy.data.meshes.new('Hollow brass pipe')
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    pipe = bpy.data.objects.new('Speaking pipe', mesh)
    bpy.context.collection.objects.link(pipe)
    finish(pipe, GOLD, smooth=True)
    # Pipe mouths and soldered lips face the keyboard.
    box((x, .102, bottom + .24), (.084, .008, .10), BLACK, .006)
    box((x, .095, bottom + .19), (.105, .016, .016), GOLD, .005)
    for z in [bottom + .05, bottom + height - .035]:
        cylinder((x, .17, z), .073, .027, GOLD, 20)


# Stepped plinth, paneled cabinet and projecting keyboard.
box((0, 0, .09), (1.90, 1.12, .18), WOOD, .035)
box((0, -.005, .19), (1.82, 1.04, .055), GOLD, .012)
box((0, .025, .74), (1.74, .88, 1.08), WOOD, .045)
for side in [-1, 1]:
    box((side * .43, -.427, .72), (.70, .025, .75), GOLD, .025)
    box((side * .43, -.447, .72), (.64, .022, .69), TEAL, .025)
    # A small fan grille on each enamel panel.
    for ray in range(-3, 4):
        angle = ray * .23
        tube_between((side * .43, -.469, .46),
                     (side * .43 + math.sin(angle) * .25, -.469,
                      .46 + math.cos(angle) * .44), .009, GOLD)
box((0, -.38, 1.18), (1.92, .72, .10), WOOD, .025)
box((0, -.40, 1.245), (1.83, .61, .035), GOLD, .008)
key_width = 1.68 / 24
for key in range(24):
    x = -.84 + (key + .5) * key_width
    box((x, -.505, 1.279), (key_width - .005, .35, .045), IVORY, .004)
    if key < 23 and key % 7 not in [2, 6]:
        box((x + key_width / 2, -.410, 1.319), (.040, .19, .055), BLACK, .004)
for side in [-1, 1]:
    box((side * .90, -.39, 1.30), (.09, .66, .15), WOOD, .018)
    for stop in range(3):
        knob = cylinder((side * .76, -.29, 1.44 + stop * .11), .035, .045, GOLD, 12)
        knob.rotation_euler.x = math.pi / 2

# An arched wooden case holds velvet behind nine graduated, open pipes.
outline = [(-.94, 1.34), (.94, 1.34)]
for point in range(25):
    x = .94 - point * 1.88 / 24
    outline.append((x, 2.82 + .38 * math.cos(x / .94 * math.pi / 2)))
vertices = [(x, y, z) for y in [.30, .43] for x, z in outline]
count = len(outline)
faces = [tuple(range(count)), tuple(range(count * 2 - 1, count - 1, -1))]
for index in range(count):
    nxt = (index + 1) % count
    faces.append((index, index + count, nxt + count, nxt))
mesh = bpy.data.meshes.new('Arched walnut case')
mesh.from_pydata(vertices, [], faces)
mesh.update()
case = bpy.data.objects.new('Arched walnut case', mesh)
bpy.context.collection.objects.link(case)
finish(case, WOOD, .012, bevel_segments=1)
box((0, .286, 2.05), (1.70, .025, 1.40), VELVET, .01)
for index in range(9):
    x = (index - 4) * .185
    hollow_pipe(x, 1.27 + .40 * math.cos(x / .8 * math.pi / 2))
for side in [-1, 1]:
    cylinder((side * .90, .16, 2.10), .070, 1.65, WOOD, 12)
    for z in [1.36, 2.86]:
        cylinder((side * .90, .16, z), .10, .08, GOLD, 12)
for point in range(24):
    x1 = -.94 + point * 1.88 / 24
    x2 = -.94 + (point + 1) * 1.88 / 24
    z1 = 2.82 + .38 * math.cos(x1 / .94 * math.pi / 2)
    z2 = 2.82 + .38 * math.cos(x2 / .94 * math.pi / 2)
    tube_between((x1, .265, z1), (x2, .265, z2), .022, GOLD)
sphere((0, .20, 3.15), (.115, .035, .115), GOLD)
for ray in range(8):
    angle = math.tau * ray / 8
    tube_between((math.sin(angle) * .025, .159, 3.15 + math.cos(angle) * .025),
                 (math.sin(angle) * .078, .159, 3.15 + math.cos(angle) * .078), .006, BLACK)

# A compact pedalboard remains inside the existing furniture clearance.
for key in range(12):
    box((-.61 + key * .111, -.62, .16), (.080, .42, .055), IVORY, .01)
export('choir_organ')
