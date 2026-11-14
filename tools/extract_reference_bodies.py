"""Derive reusable body visuals, retaining bus walls while excluding original wings."""
import argparse
import copy
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPONENT_BYTES = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
ELEMENTS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def values(document, binary, accessor_id):
    accessor = document['accessors'][accessor_id]
    view = document['bufferViews'][accessor['bufferView']]
    width = COMPONENT_BYTES[accessor['componentType']] * ELEMENTS[accessor['type']]
    stride = view.get('byteStride', width)
    start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    return [bytes(binary[start + i * stride:start + i * stride + width]) for i in range(accessor['count'])]


def append_accessor(document, binary, rows, template, target):
    binary.extend(b'\0' * (-len(binary) % 4))
    offset = len(binary)
    binary.extend(b''.join(rows))
    document['bufferViews'].append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(binary) - offset, 'target': target})
    accessor = {key: template[key] for key in ['componentType', 'type', 'normalized'] if key in template}
    accessor.update(bufferView=len(document['bufferViews']) - 1, count=len(rows))
    if template['type'] == 'VEC3' and template['componentType'] == 5126 and 'min' in template:
        points = [struct.unpack('<3f', row) for row in rows]
        accessor['min'] = [min(p[i] for p in points) for i in range(3)]
        accessor['max'] = [max(p[i] for p in points) for i in range(3)]
    document['accessors'].append(accessor)
    return len(document['accessors']) - 1


def acrimsat_bus_walls(document, binary, primitive, node):
    """Keep the centre bus from tex_01, which also contains original solar geometry.

    Evaluate the footprint AFTER the source node's rotation/scale/translation.
    Compact every vertex attribute so discarded wing vertices cannot inflate bounds.
    """
    def cross(a, b):
        return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
    def transform(point):
        scale = node.get('scale', [1, 1, 1])
        shift = node.get('translation', [0, 0, 0])
        q = node.get('rotation', [0, 0, 0, 1])
        point = tuple(point[i] * scale[i] for i in range(3))
        t = tuple(2*x for x in cross(q[:3], point))
        c = cross(q[:3], t)
        return tuple(point[i] + q[3]*t[i] + c[i] + shift[i] for i in range(3))
    points = [transform(struct.unpack('<3f', row)) for row in values(document, binary, primitive['attributes']['POSITION'])]
    template = document['accessors'][primitive['indices']]
    fmt = '<H' if template['componentType'] == 5123 else '<I'
    indices = [struct.unpack(fmt, row)[0] for row in values(document, binary, primitive['indices'])]
    retained = []
    for offset in range(0, len(indices), 3):
        triangle = indices[offset:offset + 3]
        if all(abs(points[i][0]) <= 0.415 and abs(points[i][2]) <= 0.415 for i in triangle):
            retained.extend(triangle)
    if not retained:
        raise ValueError('AcrimSAT bus-wall extraction retained no triangles')
    vertex_ids = sorted(set(retained))
    remap = {old: new for new, old in enumerate(vertex_ids)}
    result = copy.deepcopy(primitive)
    for semantic, accessor_id in primitive['attributes'].items():
        source = values(document, binary, accessor_id)
        result['attributes'][semantic] = append_accessor(document, binary, [source[i] for i in vertex_ids], document['accessors'][accessor_id], 34962)
    result['indices'] = append_accessor(document, binary, [struct.pack('<H', remap[i]) for i in retained], {'componentType': 5123, 'type': 'SCALAR'}, 34963)
    print(f'AcrimSAT: restored {len(retained) // 3} centre-wall triangles; excluded original wing structures')
    return result


def extract(number, name):
    source = (ROOT / 'assets/3d/real' / f'{name}.glb').read_bytes()
    length = struct.unpack_from('<I', source, 12)[0]
    document = json.loads(source[20:20 + length])
    binary = bytearray(source[28 + length:])
    meshes, mapping = [], {}
    for index, mesh in enumerate(document['meshes']):
        primitives = []
        for primitive in mesh['primitives']:
            material = document['materials'][primitive.get('material', 0)].get('name', '').lower()
            if 'solar' in material or (name == 'AcrimSAT' and material in ['black_krinkle', 'shiny_panel']):
                continue
            if name == 'AcrimSAT' and material == 'tex_01':
                node = next(node for node in document['nodes'] if node.get('mesh') == index)
                primitive = acrimsat_bus_walls(document, binary, primitive, node)
            primitives.append(primitive)
        if primitives:
            mapping[index] = len(meshes)
            mesh['primitives'] = primitives
            meshes.append(mesh)
    for node in document['nodes']:
        if 'mesh' in node:
            original = node.pop('mesh')
            if original in mapping:
                node['mesh'] = mapping[original]
    document['meshes'] = meshes
    document['asset']['generator'] = 'OrbitBridge body extraction from NASA ' + name
    binary.extend(b'\0' * (-len(binary) % 4))
    document['buffers'][0]['byteLength'] = len(binary)
    metadata = json.dumps(document).encode()
    metadata += b' ' * (-len(metadata) % 4)
    output = ROOT / 'assets/3d/satellite' / f'Satellite Kit body {number}.glb'
    output.write_bytes(struct.pack('<III', 0x46546c67, 2, 28 + len(metadata) + len(binary)) + struct.pack('<II', len(metadata), 0x4e4f534a) + metadata + struct.pack('<II', len(binary), 0x004e4942) + binary)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--body', choices=['AcrimSAT', 'MiRaTa', 'ICECube'])
    selected = parser.parse_args().body
    for number, name in enumerate(['AcrimSAT', 'MiRaTa', 'ICECube'], 1):
        if selected is None or selected == name:
            extract(number, name)
