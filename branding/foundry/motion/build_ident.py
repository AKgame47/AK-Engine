"""AK Engine ident scene generator for Blender 4.3+. Original AK Studio production."""
from pathlib import Path
import math, xml.etree.ElementTree as ET, re, sys
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'render'
OUT.mkdir(exist_ok=True)
MARK=ROOT.parent/'identity'/'ak-engine-mark.svg'
bpy.ops.wm.read_factory_settings(use_empty=True)
s=bpy.context.scene
s.render.engine='CYCLES'
s.cycles.samples=6
s.cycles.use_denoising=False
s.cycles.max_bounces=4
s.cycles.diffuse_bounces=2
s.cycles.glossy_bounces=2
s.cycles.use_adaptive_sampling=True
s.cycles.adaptive_threshold=.11
s.render.threads_mode='FIXED'
s.render.threads=6
s.render.resolution_x=1280
s.render.resolution_y=720
s.render.resolution_percentage=100
s.render.fps=24
s.render.image_settings.file_format='PNG'
s.render.image_settings.color_mode='RGB'
s.render.filepath=str(OUT/'frame_')
s.frame_start=1
s.frame_end=120
s.view_settings.view_transform='AgX'
s.view_settings.look='AgX - Medium High Contrast'
s.view_settings.exposure=.15
world=bpy.data.worlds.new('Graphite booth')
world.use_nodes=True
world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.215,.243,.277,1)
world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.19
s.world=world

def rgb(hex):
 x=[int(hex[i:i+2],16)/255 for i in (0,2,4)]
 return tuple(((v+.055)/1.055)**2.4 if v>.04045 else v/12.92 for v in x)
def mat(name,col,metal,rough,emission=0):
 m=bpy.data.materials.new(name)
 m.diffuse_color=(*rgb(col),1)
 m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF')
 p.inputs['Base Color'].default_value=(*rgb(col),1)
 p.inputs['Metallic'].default_value=metal
 p.inputs['Roughness'].default_value=rough
 p.inputs['Emission Color'].default_value=(*rgb(col),1)
 p.inputs['Emission Strength'].default_value=emission
 return m
al=mat('Bead-blasted aluminum','DADBD5',.42,.23,.10)
cu=mat('Brushed copper','D9A16C',.53,.26,.085)
dark=mat('Graphite platen','202326',.25,.63)
lettering=mat('Ceramic enamel','F0EEE8',.08,.29,.44)
secondary=mat('Studio signature','B3A99D',.08,.45,.22)

def vec_path(d):
 tok=re.findall(r'[MmLlHhVvZz]|[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|[AaCcQqSsTt]',d)
 i=0; cmd='M'; cur=(0,0); first=cur; contour=[]; result=[]
 while i<len(tok):
  if len(tok[i])==1 and tok[i].isalpha():
   cmd=tok[i]; i+=1
   if cmd in ('z','Z'):
    if contour: result.append(contour)
    contour=[];cur=first;continue
  if cmd not in 'MmLlHhVv': raise ValueError(f'Unexpected SVG path command {cmd}: {d}')
  x,y=cur
  if cmd in 'Hh':
   x0=float(tok[i]);i+=1;x=x0+x if cmd=='h' else x0
  elif cmd in 'Vv':
   y0=float(tok[i]);i+=1;y=y0+y if cmd=='v' else y0
  else:
   a,b=float(tok[i]),float(tok[i+1]);i+=2
   x=x+a if cmd.islower() else a; y=y+b if cmd.islower() else b
  cur=(x,y)
  if cmd in 'Mm':
   if contour: result.append(contour)
   contour=[];first=cur;cmd='l' if cmd=='m' else 'L'
  if not contour or cur!=contour[-1]: contour.append(cur)
 if contour:result.append(contour)
 return result

def source_shapes():
 root=ET.parse(MARK).getroot()
 vx,vy,vw,vh=[float(x) for x in re.split(r'[, ]+',root.attrib['viewBox'].strip())]
 def walk(n, inherited=''):
  fill=n.attrib.get('fill',inherited)
  tag=n.tag.split('}')[-1]
  if n.attrib.get('transform'):raise ValueError('Mark source contains unsupported SVG transform.')
  if tag in ('path','polygon') and fill.lower()!='none':
   if tag=='path': polys=vec_path(n.attrib['d'])
   else:
    ns=[float(v) for v in re.split(r'[ ,\s]+',n.attrib['points'].strip())]
    polys=[list(zip(ns[::2],ns[1::2]))]
   if polys:
    out.append((fill,polys))
  for child in n: walk(child,fill)
 out=[]
 walk(root)
 if not out:raise ValueError('SVG contains no paths.')
 return out,(vx,vy,vw,vh)

def shape_object(name,polys,scale,ox,oy,material):
 cv=bpy.data.curves.new(name,'CURVE')
 cv.dimensions='2D'
 cv.fill_mode='BOTH'
 cv.resolution_u=1
 cv.bevel_resolution=3
 cv.bevel_depth=.025
 cv.extrude=.105
 for contour in polys:
  if len(contour)>2 and contour[0]==contour[-1]:contour=contour[:-1]
  if len(contour)<3:continue
  spl=cv.splines.new('POLY')
  spl.points.add(len(contour)-1)
  for q,(x,y) in zip(spl.points,contour):
   q.co=((x-ox)*scale,(oy-y)*scale,0,1)
  spl.use_cyclic_u=True
 obj=bpy.data.objects.new(name,cv)
 s.collection.objects.link(obj)
 obj.data.materials.append(material)
 return obj

def pose(obj, frame, xyz, z_angle=0, rx=0, ry=0):
 obj.location=xyz;obj.rotation_euler=(rx,ry,z_angle)
 obj.keyframe_insert('location',frame=frame)
 obj.keyframe_insert('rotation_euler',frame=frame)

def light(name,coords, power,size,color,aim=(0,0,0),size_y=None):
 db=bpy.data.lights.new(name,'AREA')
 db.energy=power;db.color=color
 db.shape='RECTANGLE' if size_y is not None else 'DISK';db.size=size
 if size_y is not None:db.size_y=size_y
 o=bpy.data.objects.new(name,db);s.collection.objects.link(o);o.location=coords
 o.rotation_euler=(Vector(aim)-o.location).to_track_quat('-Z','Y').to_euler()
 return o

bpy.ops.mesh.primitive_plane_add(size=120,location=(0,0,-.64))
floor=bpy.context.object;floor.name='Graphite background';floor.data.materials.append(dark)
nodes=dark.node_tree.nodes
link=dark.node_tree.links
bs=nodes.get('Principled BSDF')
coord=nodes.new('ShaderNodeTexCoord')
v=nodes.new('ShaderNodeVectorMath');v.operation='DISTANCE';v.inputs[1].default_value=(.2,.7,0)
link.new(coord.outputs['Object'],v.inputs[0])
r=nodes.new('ShaderNodeMapRange');r.inputs['From Min'].default_value=0;r.inputs['From Max'].default_value=8
r.inputs['To Min'].default_value=1;r.inputs['To Max'].default_value=0
link.new(v.outputs['Value'],r.inputs[0])
ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.005,.006,.0075,1);ramp.color_ramp.elements[1].color=(.021,.0225,.024,1)
link.new(r.outputs[0],ramp.inputs[0])
link.new(ramp.outputs[0],bs.inputs['Emission Color'])
bs.inputs['Emission Strength'].default_value=1.0
bs.inputs['Base Color'].default_value=(.002,.0022,.0025,1)
bs.inputs['Specular IOR Level'].default_value=.02
cam_data=bpy.data.cameras.new('Orthographic wordmark')
cam_data.type='ORTHO';cam_data.ortho_scale=12.5
cam=bpy.data.objects.new('Camera',cam_data);s.collection.objects.link(cam);cam.location=(0,0,15);s.camera=cam
cam_data.ortho_scale=10.6;cam_data.keyframe_insert('ortho_scale',frame=1)
cam_data.ortho_scale=12.5;cam_data.keyframe_insert('ortho_scale',frame=72)
cam_data.keyframe_insert('ortho_scale',frame=120)
light('Main softbox',(-3.2,4.8,6.3),600,5,(1,.94,.88),size_y=3.0)
light('Rim strip',(4,-2,3.2),395,4.3,(1,.73,.53),size_y=.55)
light('Soft frontal bounce',(0,0,6.5),100,6.4,(.87,.92,1))
sweep=light('Traveling reflection',(-8,-2,2.3),290,4,(1,.92,.83),size_y=.3)
sweep.keyframe_insert('location',frame=1)
sweep.location=(4,1.3,2.8);sweep.keyframe_insert('location',frame=65)
sweep.location=(6,1.8,2.9);sweep.keyframe_insert('location',frame=120)

raw,v=source_shapes()
asset_xy=[p for _,ls in raw for poly in ls for p in poly]
x0,x1=min(p[0] for p in asset_xy),max(p[0] for p in asset_xy)
y0,y1=min(p[1] for p in asset_xy),max(p[1] for p in asset_xy)
scale=2.8/max(x1-x0,y1-y0)
mark_left,mark_mid=(75-179)*scale,.22
for j,(color,polys) in enumerate(raw):
 ps=[p for l in polys for p in l]
 ox=(min(x for x,y in ps)+max(x for x,y in ps))/2
 oy=(min(y for x,y in ps)+max(y for x,y in ps))/2
 copper=color.lower() in ('#d9a16c','#da9d6c','#deab76')
 if not copper and color.startswith('#') and len(color)==7:
  c=[int(color[1+i:3+i],16) for i in (0,2,4)]
  copper=c[0]>c[2]+20
 obj=shape_object('Copper inlay' if copper else f'Aluminum segment {j+1}',polys,scale,ox,oy,cu if copper else al)
 x=mark_left+(ox-(x0+x1)/2)*scale;y=mark_mid+((y0+y1)/2-oy)*scale
 direction=(-1 if j==0 else 1)
 opening=[(x-5.2,y+2.75,.55),(x-5,y-3.55,.4),(x+4.5,y+4.5,.52),(x+4.5,y-3.5,.65)]
 init=opening[j%len(opening)]
 start=4+j*5; end=28+j*8
 pose(obj,1,init,.13*direction,.07*direction,.13*direction)
 pose(obj,start,init,.13*direction,.07*direction,.13*direction)
 pose(obj,end-6,(x+init[0]*.075,y+init[1]*.075,.24),-.025*direction,.00,.035*direction)
 pose(obj,end,(x,y,.17),0,0,0)
 pose(obj,end+5,(x,y,.17),0,0,0)

font=bpy.data.fonts.load('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',check_existing=True)
def type_object(name,text,size,tracking,origin,material,begin,end):
 cv=bpy.data.curves.new(name,'FONT');cv.font=font;cv.body=text;cv.size=size;cv.space_character=tracking
 cv.extrude=.006;cv.bevel_depth=.001
 obj=bpy.data.objects.new(name,cv);s.collection.objects.link(obj);cv.materials.append(material)
 x,y,z=origin
 pose(obj,1,(x+.82,y-.035,-1.6));pose(obj,begin,(x+.82,y-.035,-1.6))
 pose(obj,end,(x,y,z));pose(obj,end+5,(x,y,z))
 return obj

# Use the exact custom ENGINE strokes from the companion vector lockup.
lock=ET.parse(ROOT.parent/'identity'/'ak-engine-lockup.svg').getroot()
group=next(element for element in lock if element.tag.endswith('}g'))
offset_x,offset_y=map(float,re.search(r'translate\(\s*([\d.]+)[ ,]+([\d.]+)\s*\)',group.attrib['transform']).groups())
stroke=float(group.attrib['stroke-width'])
word=bpy.data.curves.new('Custom vector ENGINE wordmark','CURVE')
word.dimensions='3D';word.resolution_u=1;word.bevel_resolution=3;word.bevel_depth=stroke*scale*.5
word.use_fill_caps=True
for p in group:
 for line in vec_path(p.attrib['d']):
  spl=word.splines.new('POLY');spl.points.add(len(line)-1)
  for xyz,(x,y) in zip(spl.points,line):
   xyz.co=(x*scale,-y*scale,0,1)
word_o=bpy.data.objects.new('ENGINE — original outlined lettering',word);s.collection.objects.link(word_o);word.materials.append(lettering)
x=(offset_x-179)*scale;y=(40-offset_y)*scale+mark_mid
pose(word_o,1,(x+.7,y,-1.5));pose(word_o,30,(x+.7,y,-1.5));pose(word_o,62,(x,y,-.51))
type_object('AK STUDIO studio credit','A K   S T U D I O',.142,1.15,(x,-.53,-.49),secondary,37,66)

# Impact accent lands with the copper key and remains strictly behind the final lockup.
def emissive(name,color,strength):
 m=bpy.data.materials.new(name);m.use_nodes=True
 nt=m.node_tree;nt.nodes.clear()
 em=nt.nodes.new('ShaderNodeEmission');em.inputs['Color'].default_value=(*rgb(color),1)
 em.inputs['Strength'].default_value=strength
 out=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],out.inputs[0])
 return m
def streak(name,length,width,mat):
 coords=[(-length*.53,0,0),(-length*.23,.5*width,0),(length*.47,.12*width,0),(length*.25,-.40*width,0)]
 me=bpy.data.meshes.new(name);me.from_pydata(coords,[],[(0,1,2,3)]);me.update()
 ob=bpy.data.objects.new(name,me);s.collection.objects.link(ob);me.materials.append(mat)
 return ob
def hitscale(obj,frame,x,y):
 obj.scale=(x,y,1);obj.keyframe_insert('scale',frame=frame)
spark_mat=emissive('Copper impact emission','F39855',3.1)
core_mat=emissive('Bright strike core','FFDBC0',5.0)
dim_mat=emissive('Outer copper stroke','A94B21',.8)
target=(-.92,.70,.86)
key=bpy.data.objects.get('Copper inlay')
target=(key.location.x,key.location.y,target[2])
# Key currently has its last inserted pose; use its actual endpoint.
for ii,(l,w,material) in enumerate([(4.4,.092,dim_mat),(4.05,.045,spark_mat),(3.92,.014,core_mat)]):
 ob=streak('Copper cut layer '+str(ii+1),l,w,material)
 pose(ob,1,target,.83);pose(ob,40,(target[0]-.61,target[1]-.56,.86+ii*.01),.83)
 pose(ob,43,(target[0]-.15,target[1]-.13,.86+ii*.01),.83)
 pose(ob,44,(*target[:2],.86+ii*.01),.83)
 pose(ob,50,(target[0]+.95,target[1]+.87,.86+ii*.01),.83)
 for f,x,y in [(1,0,0),(41,0,0),(43,.38,.65),(44,1,1),(45,.91,.53),(48,.64,.15),(51,0,0)]:
  hitscale(ob,f,x,y)
for ii in range(9):
 angle=.83+((ii*29)%37-18)*.043
 sign=-1 if ii in [2,5,8] else 1
 vd=(math.cos(angle)*sign,math.sin(angle)*sign)
 dist=.66+((ii*71)%100)/72
 ob=streak('Directional spark '+str(ii+1),.13+ii*.023,.011 if ii<7 else .015,spark_mat if ii%3 else dim_mat)
 start=44+ii%3
 p=(target[0]+vd[0]*.24,target[1]+vd[1]*.24,.81)
 end=(target[0]+vd[0]*dist,target[1]+vd[1]*dist,.84)
 pose(ob,1,p,angle);pose(ob,start,p,angle);pose(ob,start+8,end,angle-.07*sign)
 for f,x,y in [(1,0,0),(start-1,0,0),(start,1,1),(start+4,.62,.56),(start+9,0,0)]:
  hitscale(ob,f,x,y)
flash=light('Strike flash',(target[0],target[1],2.88),0,1.4,(1,.38,.12),target)
for frame,power in [(1,0),(42,0),(43,70),(44,210),(45,91),(48,18),(52,0)]:
 flash.data.energy=power;flash.data.keyframe_insert('energy',frame=frame)

# Keep editable scene, audio, and typography portable.
audio_file=ROOT/'AK-Engine-Ident-Sound.wav'
if audio_file.exists():
 ed=s.sequence_editor_create()
 strip=ed.sequences.new_sound('Original AK Studio sound design',str(audio_file),1,1)
 strip.sound.pack()
 s.sync_mode='AUDIO_SYNC'
s.render.use_sequencer=False
s.render.filepath='//render/frame_'
bpy.ops.file.pack_all()
s.frame_set(75)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'AK-Engine-Ident.blend'))
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
if args and args[0]=='preview':
 s.cycles.samples=5;s.render.resolution_percentage=67
 for frame in [16,35,80]:
  s.frame_set(frame);s.render.filepath=str(ROOT/f'preview_{frame:02}.png')
  bpy.ops.render.render(write_still=True)
elif args and args[0]=='render':
 s.render.filepath=str(OUT/'frame_')
 s.frame_set(1)
 s.frame_start=next((f for f in range(1,74) if not (OUT/f'frame_{f:04}.png').exists()),73)
 s.frame_end=73
 bpy.ops.render.render(animation=True)
