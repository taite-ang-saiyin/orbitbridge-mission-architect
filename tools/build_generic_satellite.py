"""Build editable, self-contained GLB starter parts in the NASA kit coordinate scale."""
import json, math, struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1] / 'assets/3d/satellite'
MATERIALS = [
 {'name':'Gold thermal blanket','pbrMetallicRoughness':{'baseColorFactor':[0.68,0.43,0.12,1],'metallicFactor':0.72,'roughnessFactor':0.42}},
 {'name':'Titanium structure','pbrMetallicRoughness':{'baseColorFactor':[0.34,0.42,0.49,1],'metallicFactor':0.8,'roughnessFactor':0.3}},
 {'name':'Photovoltaic cells','pbrMetallicRoughness':{'baseColorFactor':[0.015,0.065,0.23,1],'metallicFactor':0.55,'roughnessFactor':0.25}},
 {'name':'Antenna ceramic','doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':[0.78,0.83,0.86,1],'metallicFactor':0.35,'roughnessFactor':0.32}},
 {'name':'Optical aperture','pbrMetallicRoughness':{'baseColorFactor':[0.008,0.018,0.03,1],'metallicFactor':0.5,'roughnessFactor':0.16}}]
class Model:
 def __init__(self):self.parts=[]
 def box(self,name,c,s,mat):
  v=[];n=[];idx=[]
  for axis,sign in [(0,1),(0,-1),(1,1),(1,-1),(2,1),(2,-1)]:
   other=[i for i in range(3) if i!=axis];start=len(v)
   for u,w in [(-1,-1),(1,-1),(1,1),(-1,1)]:
    p=list(c);p[axis]+=sign*s[axis]/2;p[other[0]]+=u*s[other[0]]/2;p[other[1]]+=w*s[other[1]]/2;v.append(p);normal=[0,0,0];normal[axis]=sign;n.append(normal)
   order=[0,1,2,0,2,3] if ((axis!=1)==(sign>0)) else [0,2,1,0,3,2]
   idx.extend(start+i for i in order)
  self.parts.append((name,v,n,idx,mat))
 def save(self,kind):
  data=bytearray();views=[];acc=[];meshes=[];nodes=[]
  def add(values,fmt,typ,count):
   while len(data)%4:data.append(0)
   raw=struct.pack('<'+fmt*len(values),*values);views.append({'buffer':0,'byteOffset':len(data),'byteLength':len(raw)});data.extend(raw)
   acc.append({'bufferView':len(views)-1,'componentType':5126 if fmt=='f' else 5125,'count':count,'type':typ});return len(acc)-1
  for name,v,n,indices,mat in self.parts:
   pos=add([x for p in v for x in p],'f','VEC3',len(v));acc[pos]['min']=[min(p[i] for p in v) for i in range(3)];acc[pos]['max']=[max(p[i] for p in v) for i in range(3)]
   normal=add([x for p in n for x in p],'f','VEC3',len(n));ix=add(indices,'I','SCALAR',len(indices));meshes.append({'primitives':[{'attributes':{'POSITION':pos,'NORMAL':normal},'indices':ix,'material':mat}]});nodes.append({'name':name,'mesh':len(meshes)-1})
  j={'asset':{'version':'2.0','generator':'OrbitBridge generic satellite authoring'},'scene':0,'scenes':[{'nodes':list(range(len(nodes)))}],'nodes':nodes,'meshes':meshes,'materials':MATERIALS,'accessors':acc,'bufferViews':views,'buffers':[{'byteLength':len(data)}]}
  js=json.dumps(j).encode();js+=b' '*(-len(js)%4);data+=b'\0'*(-len(data)%4)
  (ROOT/f'Satellite Kit {kind} 1.glb').write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(data))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(data),0x004e4942)+data)
b=Model();b.box('ThermalBlanket',(0,0,0),(.035,.038,.032),0)
for y in [-.02,.02]:b.box('StructuralDeck',(0,y,0),(.038,.002,.035),1)
for x in [-.018,.018]:
 for z in [-.0165,.0165]:b.box('CornerRail',(x,0,z),(.0015,.04,.0015),1)
b.box('InstrumentHousing',(0,0,.018),(.02,.018,.005),1);b.box('OpticalAperture',(0,0,.021),(.012,.012,.001),4);b.save('body')
w=Model()
for side in [-1,1]:
 w.box('WingHinge',(side*.023,0,0),(.012,.002,.002),1)
 w.box('WingFrame',(side*.059,0,0),(.064,.002,.033),1)
 for col in range(12):
  for row in range(6):
   x=side*(.029+col*.0052);z=-.0135+row*.0054
   for y in [-.0011,.0011]:w.box('SolarCell',(x,y,z),(.00485,.00015,.005),2)
w.save('wings')
r=Model();r.box('AntennaMount',(0,.024,0),(.007,.009,.007),1)
v=[];norm=[];indices=[];rings=10;segments=48
for ring in range(rings+1):
 radius=.014*ring/rings
 for seg in range(segments):
  a=seg*math.tau/segments;v.append([radius*math.cos(a),.028+radius*radius/.035,radius*math.sin(a)]);normal=[-2*radius*math.cos(a)/.035,1,-2*radius*math.sin(a)/.035];length=sum(x*x for x in normal)**.5;norm.append([x/length for x in normal])
for ring in range(rings):
 for seg in range(segments):
  a=ring*segments+seg;b=ring*segments+(seg+1)%segments;c=a+segments;d=b+segments;indices.extend([a,c,b,b,c,d])
r.parts.append(('ParabolicDish',v,norm,indices,3));r.box('FeedMast',(0,.036,0),(.001,.016,.001),1);r.box('FeedHorn',(0,.044,0),(.003,.003,.003),3);r.save('radio')
