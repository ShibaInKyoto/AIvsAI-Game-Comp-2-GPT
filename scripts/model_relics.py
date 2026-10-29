"""Four original impossible antiques. Run with blender --background --python scripts/model_relics.py."""
from pathlib import Path
import sys
import math
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
from modeling import (material, clear, box, cylinder, sphere, tube_between, export,
                      finish, GOLD, WOOD, IVORY, TEAL, BLACK)


def glow(name, color, strength=.6):
    result = material(name, color, .15, .3)
    shader = result.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Emission Color'].default_value = (*color, 1)
    shader.inputs['Emission Strength'].default_value = strength
    return result


def torus(pos, radius, thickness, mat, upright=False):
    bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=8,
                                   location=pos, major_radius=radius, minor_radius=thickness)
    obj = finish(bpy.context.object, mat, smooth=True)
    if upright:
        obj.rotation_euler.x = math.pi / 2
    return obj


def lathe(profile, mat, segments=40):
    vertices = [(r*math.cos(a*math.tau/segments), r*math.sin(a*math.tau/segments), z)
                for r, z in profile for a in range(segments)]
    faces = []
    for ring in range(len(profile)-1):
        for a in range(segments):
            b = (a+1) % segments
            faces.append((ring*segments+a, ring*segments+b,
                          (ring+1)*segments+b, (ring+1)*segments+a))
    mesh = bpy.data.meshes.new('Turned antique')
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new('Turned antique', mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, mat, smooth=True)
    return obj


HOUR = glow('Stolen turquoise light', (.12, .65, .63))
BELL = glow('Choir amber inlay', (.85, .38, .055), .35)
THRESHOLD = glow('Folded threshold', (.35, .12, .55), .8)
AURORA = glow('Aurora ribbon', (.2, .75, .43), 1.0)

# An oversized pocket watch: enamel dial, twelve indices, fixed hands, winding crown.
clear()
case = cylinder((0,0,0), .29, .11, GOLD, 48)
case.rotation_euler.x = math.pi/2
for side in [-1, 1]:
    face = cylinder((0,side*.064,0), .255, .018, IVORY, 48)
    face.rotation_euler.x = math.pi/2
    torus((0,side*.078,0), .262, .012, HOUR, True)
    for hour in range(12):
        angle=hour*math.tau/12
        index=box((math.sin(angle)*.218,side*.082,math.cos(angle)*.218),
                  (.014,.012,.046 if hour%3==0 else .025),GOLD,.003)
        index.rotation_euler.y=angle
    tube_between((0,side*.09,0),(.12,side*.09,.12),.012,BLACK)
    tube_between((0,side*.093,0),(-.055,side*.093,.095),.016,BLACK)
    sphere((0,side*.096,0),(.025,.012,.025),GOLD)
cylinder((0,0,.315), .035, .06, GOLD, 20)
torus((0,0,.39),.055,.012,GOLD,True)
export('relic_hour')

# A hollow hand bell with a flared lip, visible clapper and an engraved waist.
clear()
lathe([(.075,.18),(.12,.16),(.15,.09),(.17,-.04),(.205,-.17),(.29,-.27),
       (.29,-.30),(.265,-.30),(.19,-.18),(.15,-.04),(.13,.09),(.065,.15)], GOLD)
torus((0,0,-.275),.282,.017,BELL)
torus((0,0,.08),.152,.01,TEAL)
cylinder((0,0,.23),.027,.13,WOOD,20)
torus((0,0,.36),.075,.022,GOLD,True)
tube_between((0,0,.12),(0,.035,-.29),.012,BLACK)
sphere((0,.035,-.29),(.052,.052,.052),BELL)
for a in range(8):
    angle=a*math.tau/8
    sphere((.171*math.cos(angle),.171*math.sin(angle),-.055),(.012,.012,.026),TEAL)
export('relic_bell')

# A doorway folded like a three-panel dressing screen, complete with hinges and stars.
clear()
for panel in range(3):
    angle=[-.45,0,.45][panel]
    cx=(panel-1)*.255
    cy=abs(panel-1)*.055
    parts=[]
    parts.append(box((0,0,0),(.235,.035,.63),WOOD,.012))
    parts.append(box((0,-.022,0),(.192,.012,.54),THRESHOLD,.006))
    for x in [-.112,.112]:
        parts.append(box((x,-.035,0),(.018,.018,.66),GOLD,.004))
    for z in [-.32,.32]:
        parts.append(box((0,-.035,z),(.235,.018,.018),GOLD,.004))
    for z in [-.2,.2]:
        parts.append(cylinder((.12,0,z),.018,.06,GOLD,12))
    for star in range(5):
        parts.append(sphere((math.sin(star*2.4+panel)*.067,-.04,-.2+star*.09),(.008,.009,.008),IVORY))
    if panel==1:
        parts.append(sphere((.073,-.052,-.04),(.017,.017,.017),GOLD))
    for part in parts:
        x,y,z=part.location
        part.location=(cx+x*math.cos(angle)-y*math.sin(angle),
                       cy+x*math.sin(angle)+y*math.cos(angle),z)
        part.rotation_euler.z += angle
export('relic_door')

# A stoppered apothecary bottle with an openwork brass guard and captured light.
clear()
GLASS = material('Aurora glass', (.18,.45,.35), .05, .15)
shader = GLASS.node_tree.nodes.get('Principled BSDF')
shader.inputs['Alpha'].default_value = .18
GLASS.surface_render_method = 'DITHERED'
lathe([(0,-.30),(.16,-.30),(.19,-.25),(.19,.10),(.16,.19),(.07,.25),
       (.07,.36),(.045,.36),(.045,.25),(.13,.17),(.16,.08),(.16,-.25),(0,-.27)],GLASS)
for z,r in [(-.28,.18),(.13,.18),(.31,.075)]:
    torus((0,0,z),r,.015,GOLD)
for a in range(4):
    angle=a*math.tau/4
    tube_between((.183*math.cos(angle),.183*math.sin(angle),-.27),
                 (.183*math.cos(angle),.183*math.sin(angle),.13),.009,GOLD)
cylinder((0,0,.36),.052,.08,WOOD,20)
cylinder((0,0,.406),.058,.012,GOLD,24)
for ribbon in range(3):
    verts=[]
    for step in range(20):
        t=step/19
        angle=t*math.tau*1.3+ribbon*math.tau/3
        for side in [-1,1]:
            r=.075+side*.025
            verts.append((math.cos(angle)*r,math.sin(angle)*r,-.23+t*.43))
    mesh=bpy.data.meshes.new('Captured ribbon')
    mesh.from_pydata(verts,[],[(i*2,i*2+1,i*2+3,i*2+2) for i in range(19)])
    mesh.update()
    obj=bpy.data.objects.new('Captured ribbon',mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj,AURORA)
export('relic_aurora')
