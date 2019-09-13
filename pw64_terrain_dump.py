import argparse
import collections
import io
import os
import struct
import sys


def decompress_mio0(raw_bytes):
    magic = raw_bytes[:4]
    assert magic == b'MIO0'

    uncompressed_size, lengths_offs, data_offs = struct.unpack('>LLL', raw_bytes[4:16])
    flags_offs = 0x10

    output = b""
    while True:
        command_byte = raw_bytes[flags_offs]
        flags_offs += 1

        for i in reversed(range(8)):
            if command_byte & (1 << i):
                # Literal
                uncompressed_size -= 1
                output += bytes([raw_bytes[data_offs]])
                data_offs += 1
            else:
                # LZSS
                tmp, = struct.unpack('>H', raw_bytes[lengths_offs:lengths_offs+2])
                lengths_offs += 2

                window_offset = (tmp & 0x0FFF) + 1
                window_length = (tmp >> 12) + 3
                uncompressed_size -= window_length
                for j in range(window_length):
                    output += bytes([output[-window_offset]])

            if uncompressed_size <= 0:
                return output

table_start = 0xde720
files_start = 0xdf5b0

def parse_file_table(rom):
    rom.seek(table_start)
    rom.seek(0x24, 1) # skip UVRM header and padding
    assert rom.read(4) == b'GZIP'
    zipped_size = int.from_bytes(rom.read(4),"big")
    assert rom.read(4) == b'TABL'
    full_size = int.from_bytes(rom.read(4),"big")
    zipped_data = rom.read(zipped_size)
    full_table = decompress_mio0(zipped_data)
    assert len(full_table) == full_size

    files = collections.defaultdict(list)
    rom.seek(files_start)
    for i in range(0, full_size, 8):
        tag = full_table[i:i+4].decode("utf8")
        size = int.from_bytes(full_table[i+4:i+8],"big")
        files[tag].append(rom.read(size)) # not strictly right, there is a misc list
        
    return files

def parse_container_comms(data, container_tag, handler):
    results = []
    with io.BytesIO(data) as f:
        assert f.read(4).decode("utf8") == "FORM"
        assert int.from_bytes(f.read(4), "big") + 8 == len(data)
        assert f.read(4).decode("utf8") == container_tag
        while f.tell() < len(data):
            curr_offset = f.tell()
            tag = f.read(4).decode("utf8")
            size = int.from_bytes(f.read(4), "big")
            dest = f.tell() + size
            if tag == "GZIP":
                assert f.read(4).decode("utf8") == "COMM"
                full_size = int.from_bytes(f.read(4),"big")
                full_data = decompress_mio0(f.read(size))
                assert len(full_data) == full_size
                with io.BytesIO(full_data) as decomp_f:
                    results.append(handler(decomp_f, curr_offset))
            elif tag != "PAD ":
                assert tag == "COMM"
                results.append(handler(f, curr_offset))
            f.seek(dest) # this feels wrong but it's what the game does and there's seemingly random padding
    return results

def dump_terra_objs(file_table, out_dir):
    for i, terra in enumerate(file_table["UVTR"]):
        # seems like there should only be one
        all_files = parse_container_comms(terra, "UVTR", lambda f, addr: handle_terra_comm(f, addr, file_table, out_dir, i))
        print(f"dumped {len(all_files)} files")

id_matrix = struct.pack(">ffffffffffff",
                        1,0,0,0,
                        0,1,0,0,
                        0,0,1,0)

def handle_terra_comm(f, address, file_table, out_dir, index):
    _xmin, _ymin = struct.unpack(">ff",f.read(8))
    f.seek(0x10,1) # some floats
    gridW, gridH, cellX, cellY, _ = struct.unpack(">bbfff",f.read(0xe))
    all_verts = []
    all_faces = []
    for i in range(gridW*gridH):
        if f.read(1)[0] == 0:
            continue # cell is empty
        assert f.read(0x30) == id_matrix
        center_x,center_y,center_z,one,rotation, contour_index = struct.unpack(">ffffbH", f.read(0x13))
        assert center_z == 0.0
        assert one == 1.0
        assert rotation == 0
                          
        contour_data = parse_container_comms(
            file_table["UVCT"][contour_index],
            "UVCT",
            lambda z, _: handle_contour_comm(z, center_x, center_y, vert_offset = len(all_verts)))
        assert len(contour_data) == 1, "Multiple COMMs in UVTR"
        verts, faces = contour_data[0]
        all_verts += verts
        all_faces += faces

    filename = os.path.join(out_dir, f"terra_{index}_{address:x}.obj")
    out = open(filename,"w+")
    for v in all_verts:
        print("v",*v, file=out)
    for i, f_group in enumerate(all_faces):
        print("g", "g"+str(i), file = out)
        for f in f_group:
            print("f", *f, file = out)
    out.close()
    return filename
                
def handle_contour_comm(f, center_x, center_y, vert_offset = 0):
    n_verts, n_faces, n_dunno, n_planes = struct.unpack(">HHHH",f.read(8))
    verts = []
    for i in range(n_verts):
        v = struct.unpack(">hhhhll",f.read(0x10)) # not sure on the rest
        verts.append((v[0] + center_x, v[1]+ center_y, v[2]))
    face_data = f.read(n_faces << 3)
    for i in range(n_dunno):
        b = f.read(1)[0]
        f.seek(0x12+b*0x40,1) # have yet to understand this data
    face_groups = []
    for i in range(n_planes):
        _, _, _, group_size, pairs = struct.unpack(">HHHHH",f.read(0xa))
        for j in range(pairs):
            if f.read(1)[0] & 0x40:
                f.seek(1,1)
            else:
                f.seek(2,1)
        face_index = int.from_bytes(f.read(2), 'big')
        curr_group = []
        for j in range(group_size):
            data = struct.unpack(">HHHH", face_data[(face_index+j) << 3: (face_index+j+1) << 3])
            curr_group.append([o + 1 + vert_offset for o in data[:3]]) # not sure about data[3]
        face_groups.append(curr_group)
        f.seek(0x16,1)
    return verts, face_groups

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument("rom", help="ROM file")
    ap.add_argument("out_dir", help="output dir")
    args = ap.parse_args()
    with open(args.rom, 'rb') as rom:
        ft = parse_file_table(rom)
    dump_terra_objs(ft, args.out_dir)
