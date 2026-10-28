"""Original modeled props. Regenerate with: blender --background --python scripts/model_props.py
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


# A two-place tufted carriage settee: two seat pads, a curved-looking back and brass piping.
clear()
box((0,0,.27),(1.94,1.04,.22),WOOD,.06)
for x in [-.82,.82]:
    for y in [-.35,.35]:
        cylinder((x,y,.14),.035,.28,GOLD,12)
box((0,.43,.86),(1.94,.18,1.04),WOOD,.07)
box((0,.31,.88),(1.8,.18,.9),VELVET,.085)
for x in [-.47,.47]:
    box((x,-.04,.49),(.89,.86,.26),VELVET,.1)
for x in [-.93,.93]:
    box((x,-.02,.79),(.16,1.1,.13),WOOD,.065)
    tube_between((x,-.5,.73),(x,.43,.73),.026,GOLD)
    tube_between((x,-.43,.38),(x,-.43,.73),.023,GOLD)
for x in [-.65,-.22,.22,.65]:
    for z in [.7,.96,1.2]:
        sphere((x,.205,z),(.027,.014,.027),GOLD)
tube_between((-.87,.20,1.33),(.87,.20,1.33),.015,GOLD)
export('settee')

# An observatory telescope, lens cap rings and braced tripod.
clear()
for angle in [0,math.tau/3,math.tau*2/3]:
    foot = (math.cos(angle)*.55, math.sin(angle)*.55, .035)
    tube_between(foot,(0,0,1.2),.028,WOOD)
    cylinder(foot,.065,.045,GOLD,12)
cylinder((0,0,1.25),.095,.26,GOLD)
axis = Vector((.2,-.93,.32)).normalized()
center = Vector((0,0,1.65))
for offset, radius, length, mat in [(-.35,.135,.3,BLACK),(0,.17,.6,TEAL),(.4,.185,.24,GOLD),(.55,.19,.08,GOLD),(-.65,.065,.23,GOLD)]:
    obj = cylinder(center+axis*offset,radius,length,mat)
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = axis.to_track_quat('Z','Y')
for offset in [-.27,.28,.47]:
    obj=cylinder(center+axis*offset,.192,.035,GOLD)
    obj.rotation_mode='QUATERNION'; obj.rotation_quaternion=axis.to_track_quat('Z','Y')
lens=cylinder(center+axis*.6,.165,.012,GLASS)
lens.rotation_mode='QUATERNION'; lens.rotation_quaternion=axis.to_track_quat('Z','Y')
sphere((.3,0,1.55),(.12,.12,.12),GOLD)
export('telescope')

# A winter fern: curved fronds assembled from tapered leaves, in a ribbed ceramic urn.
clear()
cylinder((0,0,.26),.30,.5,TEAL,32,radius_top=.39)
cylinder((0,0,.5),.40,.06,GOLD,32)
cylinder((0,0,.53),.34,.018,SOIL,24)
cylinder((0,0,.07),.33,.06,GOLD,24)
for a in range(13):
    angle=a*math.tau/13
    spread=.38 + .18*random.random()
    height=.7 + .5*random.random()
    points=[]
    for i in range(7):
        t=i/6
        r=spread*t
        p=(math.cos(angle)*r, math.sin(angle)*r, .54+height*math.sin(t*1.8))
        points.append(p)
        if i:
            tube_between(points[i-1],p,.008,LEAF)
        if 0<i<6:
            for side in [-1,1]:
                leaf_angle=angle+side*1.1
                length=.2*(1-.55*t)
                end=(p[0]+math.cos(leaf_angle)*length,p[1]+math.sin(leaf_angle)*length,p[2]+.05)
                middle=Vector(p).lerp(Vector(end),.52)
                leaf=sphere(middle,(.035,length*.6,.012),LEAF_LIGHT if a%3==0 else LEAF)
                leaf.rotation_euler.z=leaf_angle-math.pi/2
export('winter_fern')

# An intimate restaurant table: linen, two place settings, stemware and a candle.
clear()
cylinder((0,0,.08),.42,.09,BLACK)
cylinder((0,0,.58),.055,1.05,GOLD)
box((0,0,1.13),(1.4,1.7,.1),WOOD,.07)
box((0,0,1.20),(1.43,1.73,.035),IVORY,.015)
for x in [-.4,.4]:
    box((x,0,1.04),(.015,1.75,.28),IVORY,.004)
for y in [-.53,.53]:
    cylinder((0,y,1.24),.23,.028,GOLD,32)
    cylinder((0,y,1.26),.195,.025,IVORY,32)
    for x in [-.31,.31]:
        box((x,y,1.25),(.025,.35,.018),GOLD,.008)
    cylinder((.42,y,1.34),.01,.18,GOLD,12)
    sphere((.42,y,1.45),(.07,.07,.085),GLASS)
    cylinder((.42,y,1.25),.06,.012,GOLD,16)
cylinder((0,0,1.26),.11,.05,GOLD)
cylinder((0,0,1.47),.025,.4,GOLD,16)
cylinder((0,0,1.75),.035,.18,IVORY,16)
sphere((0,0,1.88),(.018,.018,.045),GOLD)
export('dining_table')

# Walnut library cabinet, uneven books and glinting spine bands.
clear()
box((0,.05,1.13),(1.7,.78,2.26),WOOD,.045)
for level in range(4):
    z=.2+level*.49
    box((0,-.40,z),(1.63,.08,.065),GOLD,.008)
    x=-.73
    for book in range(9):
        width=random.uniform(.09,.16)
        height=random.uniform(.28,.40)
        box((x+width/2,-.41,z+.04+height/2),(width-.015,.20,height),BOOKS[(book+level)%4],.01)
        for band in [.08,height-.06]:
            box((x+width/2,-.516,z+.04+band),(width-.03,.015,.012),GOLD,.003)
        x+=width+.03
box((0,-.41,2.23),(1.8,.12,.12),WOOD,.035)
for x in [-.78,.78]:
    box((x,-.42,1.12),(.075,.10,2.15),GOLD,.015)
export('bookcase')

# Stacked travel cases, stitched leather, latches and raised handles.
clear()
for center,size in [((0,0,.24),(1.1,.65,.42)),((.08,.03,.62),(.85,.58,.32))]:
    x,y,z=center; w,d,h=size
    box(center,size,LEATHER,.055)
    for side in [-1,1]:
        box((x+side*w*.31,y,z),(0.045,d+.015,h+.015),GOLD,.012)
        box((x+side*w*.23,y-d/2-.015,z+.02),(.085,.03,.10),GOLD,.01)
    for dx in [-.12,.12]:
        box((x+dx,y-d/2-.03,z+h*.2),(.035,.06,.10),WOOD,.012)
    box((x,y-d/2-.055,z+h*.2+.05),(.26,.055,.035),WOOD,.015)
export('luggage')

# The conductor: tailored silhouette, porcelain mask, brass insignia and a red cage lantern.
COAT = material('Midnight coat', (.025,.045,.075), .08, .65)
MASK = material('Porcelain mask', (.78,.79,.68), .05, .3)
RED_GLASS = material('Conductor lantern', (.7,.08,.035), .1, .2)
RED_GLASS.node_tree.nodes.get('Principled BSDF').inputs['Emission Color'].default_value=(.8,.08,.02,1)
RED_GLASS.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.5


def person(conductor=False):
    clear()
    cloth = COAT if conductor else TEAL
    for x in [-.15,.15]:
        box((x,-.05,.12),(.19,.37,.18),BLACK,.07)
        box((x,.01,.42),(.16,.2,.52),cloth,.045)
    cylinder((0,.02,.91),.38,.9,cloth,12,radius_top=.23)
    box((0,.02,1.44),(.56,.36,.56),cloth,.09)
    # Narrow gold lapels and a central line of uniform buttons.
    for side in [-1,1]:
        lapel=box((side*.1,-.19,1.55),(.085,.035,.32),GOLD,.012)
        lapel.rotation_euler.y=side*.24
        tube_between((side*.28,.02,1.61),(side*.38,-.03,1.11),.075,cloth)
        tube_between((side*.38,-.03,1.11),(side*.37,-.22,1.04),.065,cloth)
        sphere((side*.37,-.22,1.02),(.067,.07,.085),MASK)
        box((side*.25,.01,1.7),(.15,.27,.04),GOLD,.012)
    for z in [1.0,1.2,1.4]:
        sphere((0,-.192,z),(.024,.012,.024),GOLD)
    cylinder((0,0,1.78),.065,.18,MASK,16)
    sphere((0,-.015,1.98),(.18,.16,.23),MASK)
    for side in [-1,1]:
        sphere((side*.071,-.157,2.025),(.042,.015,.026),BLACK)
    if conductor:
        box((0,-.176,1.89),(.06,.015,.014),BLACK,.004)
    cylinder((0,0,2.19),.34,.045,BLACK,32)
    cylinder((0,0,2.32),.205,.23,cloth,32,radius_top=.19)
    cylinder((0,0,2.24),.21,.05,GOLD,32)
    if conductor:
        # A handle over the lantern, and a glass core inside four brass rods.
        tube_between((.37,-.22,1.02),(.48,-.24,.96),.025,GOLD)
        box((.48,-.24,.78),(.24,.24,.3),RED_GLASS,.015)
        for height in [.6,.96]:
            box((.48,-.24,height),(.3,.3,.045),GOLD,.018)
        for dx in [-.13,.13]:
            for dy in [-.13,.13]:
                tube_between((.48+dx,-.24+dy,.62),(.48+dx,-.24+dy,.94),.013,GOLD)
    else:
        box((0,-.27,1.06),(.28,.035,.18),GOLD,.012)
        for x in [-.08,0,.08]:
            box((x,-.292,1.06),(.008,.006,.1),BLACK,.001)
    export('conductor' if conductor else 'passenger')

person(True)
person(False)
