"""Derive reusable body visuals from NASA references, retaining source materials."""
import json,struct,copy
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for number,name in enumerate(['AcrimSAT','MiRaTa','ICECube'],1):
 b=(root/'assets/3d/real'/f'{name}.glb').read_bytes();n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);binary=b[28+n:];meshes=[];mapping={}
 for i,mesh in enumerate(j['meshes']):
  primitives=[]
  for p in mesh['primitives']:
   material=j['materials'][p.get('material',0)].get('name','').lower()
   if 'solar' in material or (name=='AcrimSAT' and material in ['black_krinkle','shiny_panel','tex_01']):continue
   primitives.append(p)
  if primitives:
   mapping[i]=len(meshes);mesh['primitives']=primitives;meshes.append(mesh)
 for node in j['nodes']:
  if 'mesh' in node:
   original=node.pop('mesh')
   if original in mapping:node['mesh']=mapping[original]
 j['meshes']=meshes;j['asset']['generator']='OrbitBridge body extraction from NASA '+name
 js=json.dumps(j).encode();js+=b' '*(-len(js)%4)
 out=root/'assets/3d/satellite'/f'Satellite Kit body {number}.glb'
 out.write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary)
