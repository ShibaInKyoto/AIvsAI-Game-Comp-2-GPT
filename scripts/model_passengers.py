"""Four original masked travelers. Run with Blender 4.3 in background mode."""
from functools import partial
from pathlib import Path
import math
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from modeling import (BLACK, GOLD, GLASS, IVORY, LEATHER, PAGE, WOOD,
                      box as base_box, clear, cylinder as base_cylinder, export,
                      finish, material, sphere, tube_between as base_tube)

# Small figures benefit from highlights, not many segments on every edge.
box = partial(base_box, bevel_segments=1)
cylinder = partial(base_cylinder, bevel_segments=1)
tube = partial(base_tube, bevel_segments=1)
MASK = material('Traveler porcelain', (.78, .79, .68), .05, .3)
CLOTH = [material('Astronomer blue wool', (.065, .16, .23), 0, .85),
         material('Archivist plum wool', (.19, .095, .20), 0, .85),
         material('Soloist green velvet', (.055, .22, .15), 0, .9),
         material('Passenger gray wool', (.16, .17, .18), 0, .9)]


def ring(pos, radius, thickness, mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=20, minor_segments=6,
                                   location=pos, major_radius=radius,
                                   minor_radius=thickness,
                                   rotation=(math.pi / 2, 0, 0))
    return finish(bpy.context.object, mat, smooth=True)


def body(identity):
    cloth = CLOTH[identity]
    for side in [-1, 1]:
        box((side * .15, -.05, .12), (.19, .37, .18), BLACK, .055)
        box((side * .15, .01, .42), (.16, .2, .52), cloth, .04)
    cylinder((0, .02, .91), .36 if identity != 2 else .43, .9, cloth,
             16, radius_top=.24)
    box((0, .02, 1.44), (.56, .36, .56), cloth, .07)
    for side in [-1, 1]:
        lapel = box((side * .1, -.19, 1.55), (.085, .035, .32), GOLD, .01)
        lapel.rotation_euler.y = side * .24
        tube((side * .28, .02, 1.61), (side * .38, -.03, 1.11), .075, cloth)
        tube((side * .38, -.03, 1.11), (side * .37, -.22, 1.04), .065, cloth)
        sphere((side * .37, -.22, 1.02), (.067, .07, .085), MASK)
    for z in [1.0, 1.2, 1.4]:
        cylinder((0, -.196, z), .022, .016, GOLD, 12).rotation_euler.x = math.pi / 2
    cylinder((0, 0, 1.78), .065, .18, MASK, 12)
    sphere((0, -.015, 1.98), (.18, .16, .23), MASK)
    for side in [-1, 1]:
        sphere((side * .071, -.157, 2.025), (.042, .015, .026), BLACK)


def astronomer():
    # A broad felt brim and a brass star chart distinguish the sky watcher.
    cylinder((0, 0, 2.19), .34, .035, CLOTH[0], 32)
    cylinder((0, 0, 2.29), .195, .21, CLOTH[0], 24, radius_top=.17)
    cylinder((0, 0, 2.22), .20, .025, GOLD, 24)
    points = [(-.17, -.215, 1.65), (-.09, -.215, 1.52),
              (.03, -.215, 1.59), (.17, -.215, 1.42)]
    for point in points:
        sphere(point, (.017, .012, .017), GOLD)
    for start, end in zip(points, points[1:]):
        tube(start, end, .005, GOLD)
    # Collapsed telescope, slung beside her gloved hand.
    start, end = (.46, -.25, .65), (.46, -.25, 1.25)
    tube(start, end, .075, GOLD)
    for z in [.65, .75, 1.15, 1.25]:
        cylinder((.46, -.25, z), .085, .035, BLACK if z == 1.15 else GOLD, 20)
    cylinder((.46, -.25, 1.27), .064, .015, GLASS, 20)
    tube((.24, .04, 1.65), (.46, -.25, .86), .014, LEATHER)


def archivist():
    cylinder((0, 0, 2.22), .19, .14, CLOTH[1], 24, radius_top=.15)
    cylinder((0, 0, 2.17), .20, .025, GOLD, 24)
    for side in [-1, 1]:
        ring((side * .073, -.177, 2.025), .055, .006, GOLD)
    tube((-.02, -.18, 2.025), (.02, -.18, 2.025), .006, GOLD)
    # A page block inside two leather covers; a ribbon marks tomorrow's date.
    box((0, -.285, 1.10), (.57, .12, .40), WOOD, .018)
    box((0, -.36, 1.10), (.53, .035, .36), PAGE, .008)
    for x in [-.28, .28]:
        box((x, -.30, 1.10), (.025, .15, .42), LEATHER, .005)
    for z in [.96, 1.04, 1.12, 1.20]:
        box((0, -.381, z), (.40, .005, .006), WOOD, 0)
    box((.16, -.388, 1.03), (.025, .008, .36), CLOTH[1], .002)


def soloist():
    # An asymmetric beret, a gold clasp and a broad velvet shoulder wrap.
    hat = sphere((.06, 0, 2.22), (.26, .20, .095), CLOTH[2])
    hat.rotation_euler.y = -.18
    for side in [-1, 1]:
        panel = box((side * .20, .01, 1.62), (.30, .43, .15), CLOTH[2], .05)
        panel.rotation_euler.y = side * .24
    sphere((0, -.23, 1.62), (.045, .02, .045), GOLD)
    box((0, -.29, 1.09), (.57, .055, .38), CLOTH[2], .015)
    box((0, -.326, 1.10), (.53, .015, .34), IVORY, .006)
    # Five staff lines and three notes on the folio; all modeled geometry.
    for z in [1.04, 1.075, 1.11, 1.145, 1.18]:
        box((0, -.338, z), (.45, .005, .004), BLACK, 0)
    for x, z in [(-.16, 1.075), (0, 1.11), (.14, 1.145)]:
        sphere((x, -.345, z), (.027, .008, .016), BLACK)
        box((x + .024, -.345, z + .055), (.005, .006, .11), BLACK, 0)


def last_passenger():
    cylinder((0, -.015, 2.20), .21, .10, CLOTH[3], 24, radius_top=.17)
    box((0, -.17, 2.18), (.32, .22, .035), BLACK, .04)
    box((0, -.205, 1.72), (.29, .065, .12), IVORY, .025)
    scarf = box((.12, -.23, 1.43), (.14, .045, .50), IVORY, .012)
    scarf.rotation_euler.y = .15
    for z in [1.22, 1.29, 1.36]:
        box((.12, -.257, z), (.14, .005, .012), CLOTH[3], 0)
    # A well-traveled case below the right hand, leaving the coat silhouette clear.
    box((.51, -.20, .55), (.42, .25, .55), LEATHER, .04)
    for z in [.39, .70]:
        box((.51, -.331, z), (.43, .018, .035), GOLD, .005)
    for x in [.38, .64]:
        box((x, -.338, .64), (.045, .018, .07), GOLD, .005)
    for x in [.43, .59]:
        tube((x, -.20, .83), (x, -.20, .94), .014, BLACK)
    tube((.43, -.20, .94), (.59, -.20, .94), .018, BLACK)


def build_passengers():
    for identity, accessory in enumerate([astronomer, archivist, soloist, last_passenger]):
        clear()
        body(identity)
        accessory()
        export(['traveler_astronomer', 'traveler_archivist',
                'traveler_soloist', 'traveler_last'][identity])


if __name__ == '__main__':
    build_passengers()
