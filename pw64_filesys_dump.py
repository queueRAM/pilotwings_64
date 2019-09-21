#!/usr/bin/env python

import argparse
import binascii
import struct
import sys

def auto_int(x):
    return int(x, 0)

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

def print_adat_decoded(hex_data):
    # The DATA blocks in the ADAT container appear to be "coded" ASCII strings.
    # The strings use a sort of look-up table as seen below.
    # This was probably done for easier localization (Kanji font textures?)
    # The Font Sprite/Texture maps are in the "STRG" container/blocks.
    # This table was extrapolated from the FS dump and PJ64 memory searches.
    char_map_combined = { # // Normal Font //
                          '00': '0', '01': '1', '02': '2', '03': '3', '04': '4',
                          '05': '5', '06': '6', '07': '7', '08': '8', '09': '9',
                          '0A': 'A', '0B': 'B', '0C': 'C', '0D': 'D', '0E': 'E',
                          '0F': 'F', '10': 'G', '11': 'H', '12': 'I', '13': 'J',
                          '14': 'K', '15': 'L', '16': 'M', '17': 'N', '18': 'O',
                          '19': 'P', '1A': 'Q', '1B': 'R', '1C': 'S', '1D': 'T',
                          '1E': 'U', '1F': 'V', '20': 'W', '21': 'X', '22': 'Y',
                          '23': 'Z', '24': 'a', '25': 'b', '26': 'c', '27': 'd',
                          '28': 'e', '29': 'f', '2A': 'g', '2B': 'h', '2C': 'i',
                          '2D': 'j', '2E': 'k', '2F': 'l', '30': 'm', '31': 'n',
                          '32': 'o', '33': 'p', '34': 'q', '35': 'r', '36': 's',
                          '37': 't', '38': 'u', '39': 'v', '3A': 'w', '3B': 'x',
                          '3C': 'y', '3D': 'z', '3E': '-', '3F': '#', '40': '<',
                          '41': '>', '42': ' ', '43': '\"', '44': '(', '45': ')',
                          '46': '*', '47': '&', '48': ',', '49': '.', '4A': '/',
                          '4B': '!', '4C': '?', '4D': '\'', '4E': '#', '4F': ':',
                          '50': '0', '51': '1', '52': '2', '53': '3', '54': '4',
                          '55': '5', '56': '6', '57': '7', '58': '8', '59': '9',
                          '5A': '\\', '5B': '\\', '5C': '\\', '5D': '\\',
                          '5E': '\\', '5F': '\\',
                          # // Bold Font //
                          '60': '0', '61': '1', '62': '2', '63': '3', '64': '4',
                          '65': '5', '66': '6', '67': '7', '68': '8', '69': '9',
                          '6A': 'A', '6B': 'B', '6C': 'C', '6D': 'D', '6E': 'E',
                          '6F': 'F', '70': 'G', '71': 'H', '72': 'I', '73': 'J',
                          '74': 'K', '75': 'L', '76': 'M', '77': 'N', '78': 'O',
                          '79': 'P', '7A': 'Q', '7B': 'R', '7C': 'S', '7D': 'T',
                          '7E': 'U', '7F': 'V', '80': 'W', '81': 'X', '82': 'Y',
                          '83': 'Z', '84': 'a', '85': 'b', '86': 'c', '87': 'd',
                          '88': 'e', '89': 'f', '8A': 'g', '8B': 'h', '8C': 'i',
                          '8D': 'j', '8E': 'k', '8F': 'l', '90': 'm', '91': 'n',
                          '92': 'o', '93': 'p', '94': 'q', '95': 'r', '96': 's',
                          '97': 't', '98': 'u', '99': 'v', '9A': 'w', '9B': 'x',
                          '9C': 'y', '9D': 'z', '9E': '-', '9F': '#', 'A0': '<',
                          'A1': '>', 'A2': ' ', 'A3': '\"', 'A4': '(', 'A5': ')',
                          'A6': '*', 'A7': '&', 'A8': ',', 'A9': '.', 'AA': '/',
                          'AB': '!', 'AC': '?', 'AD': '\'', 'AE': '}', 'AF': ':',
                          'B0': '0', 'B1': '1', 'B2': '2', 'B3': '3', 'B4': '4',
                          'B5': '5', 'B6': '6', 'B7': '7', 'B8': '8', 'B9': '9',
                          'BA': '\\', 'BB': '\\', 'BC': '\\', 'BD': '\\',
                          'BE': '\\', 'BF': '\\' }

    # Take the raw binary data and convert to Hex
    hex_data = str(binascii.b2a_hex(hex_data),'ascii')

    # Split input stream of characters into hex bytes
    hex_split = [(hex_data[i:i+2]) for i in range(0, len(hex_data), 2)]

    # There are various "command" codes that I haven't figured out yet.
    # They are detected below.
    # Special "turn on bold" command (until newline)?
    #   00 fd | 00 d4 | 00 00 | 00 4a
    #   00 fd | 00 69 | 00 00 | 00
    # Turn off bold?
    #   00 fd | 00 7d | 00 00
    # Weird ">" arrow in Sound settings
    #   00 fd | 00 b4 | 00 00 00

    # Empty list for storing final string
    adat_final_string = []

    # Read a pair of hex bytes
    for i in range(0, len(hex_split), 2):
        hex_pair = hex_split[i:i+2]

        char_byte1 = hex_pair[0].upper()
        char_byte2 = hex_pair[1].upper()

        if char_byte1 == '00':
          if char_byte2 == 'CA':
              # slash? '\' ?
              pass
          elif char_byte2 == 'D4':
              # Unknown char
              pass
          elif char_byte2 == 'FE':
              # Newline
              adat_final_string.append('\n')
          elif char_byte2 == 'FD':
              # Tab?
              pass
          elif char_byte2 == 'FF':
              # EOF/EOS
              break
          else:
              adat_final_string.append(char_map_combined[char_byte2])
        else:
          # We found some weird control char in our pair?
          adat_final_string.append('?0')

    print('    --------- Decoded String ---------')
    for line in "".join(adat_final_string).splitlines():
        print ('    %s' % line)
    print('    ----------------------------------')

def print_hex_dump(raw_bytes):
    count = 0
    for b in raw_bytes:
        if count % 16 == 0:
            sys.stdout.write(' ' * 4)
        sys.stdout.write('{:02x} '.format(b))
        count += 1
        if count % 16 == 0:
            sys.stdout.write('\n')
    if count % 16:
        sys.stdout.write('\n')

def pw64_dump_filesys(fname, startOffset, hexSize):
    def hexdump(raw_bytes):
        if hexSize > 0:
            if len(raw_bytes) > hexSize:
                raw_bytes = raw_bytes[:hexSize]
            print_hex_dump(raw_bytes)

    with open(fname, 'rb') as fin:
        fin.seek(startOffset)
        dumping = True
        while (dumping):
            fileOffset = fin.tell()
            sys.stdout.write('0x%06X|%06X: ' % (fileOffset, fileOffset - startOffset))
            magic = fin.read(4)
            magicInt = int.from_bytes(magic, byteorder='big')
            if magicInt == 0:
                print('00000000 [EOF]')
                break
            magicStr = magic.decode('utf-8')
            if magicStr == 'FORM':
                formLength = int.from_bytes(fin.read(4), byteorder='big')
                formEnd = fin.tell() + formLength
                print('%s: 0x%06X (end: 0x%06X)' % (magicStr, formLength, formEnd))
                while (fin.tell() < formEnd):
                    fileOffset = fin.tell()
                    sys.stdout.write('0x%06X|%06X: ' % (fileOffset, fileOffset - startOffset))
                    magic = fin.read(4)
                    magicStr = magic.decode('utf-8')
                    # no length on these
                    if magicStr in ['UVSY', 'UVEN', 'UVLT', 'UVTR', 'UVLV',
                                    'UVSQ', 'UVTP', 'UVMD', 'UVCT', 'UVTX',
                                    'UVAN', 'UVFT', 'UPWL', 'SPTH', 'UPWT',
                                    'ADAT', '3VUE', 'PDAT', 'UVBT', 'UVSX',
                                    'UVRM']:
                        print('  %s' % magicStr)
                        blockType = magicStr
                    elif magicStr == 'NAME': # ASCII name identifier
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        name = fin.read(length)
                        nameStr = name.decode('utf-8').rstrip('\0')
                        print('  %s: 0x%06X: %s' % (magicStr, length, nameStr))
                    elif magicStr == 'INFO': # usually mission objective
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        info = fin.read(length)
                        infoStr = info.decode('utf-8').rstrip('\0')
                        print('  %s: 0x%06X: %s' % (magicStr, length, infoStr))
                    elif magicStr == 'JPTX': # some ASCII identifier
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        info = fin.read(length)
                        infoStr = info.decode('utf-8').rstrip('\0')
                        print('  %s: 0x%06X: %s' % (magicStr, length, infoStr))
                    elif magicStr == 'GZIP': # not actually gzip, but MIO0 container
                        gzipLength = int.from_bytes(fin.read(4), byteorder='big')
                        absOffset = fin.tell() + gzipLength
                        decompType = fin.read(4)
                        decompTypeStr = decompType.decode('utf-8')
                        decompLength = int.from_bytes(fin.read(4), byteorder='big')

                        compBytes = fin.read(gzipLength - 8)
                        decompBytes = decompress_mio0(compBytes)

                        print('  %s: 0x%06X: %s' % (magicStr, gzipLength, decompTypeStr))
                        hexdump(decompBytes)
                    # generic handler for lengths that are not yet parsed
                    elif magicStr == 'COMM':
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        sectionData = fin.read(length)
                        print('  %s: 0x%06X:' % (magicStr, length))
                        if blockType == 'UVSQ':
                            count = int(sectionData[0])
                            uvsq = '>Hf'
                            # +1 becuase last u16/float might be special
                            for i in range(count + 1):
                                (idx, val) = struct.unpack(uvsq, sectionData[1+6*i:7+6*i])
                                print('    0x%04X: %f' % (idx, val))
                        else:
                            hexdump(sectionData)
                    # generic handler for lengths that are not yet parsed
                    elif magicStr in ['PART', 'STRG', 'FRMT', 'ESND',
                                      'TPAD', 'CNTG', 'HOPD', 'LWIN', 'LSTP',
                                      'TARG', 'FALC', 'BALS', 'HPAD', 'BTGT',
                                      'THER', 'PHTS', 'SIZE', 'QUAT', 'XLAT',
                                      'PHDR', 'RHDR', 'PPOS', 'RPKT',
                                      '.CTL', '.TBL',
                                      'SCPP', 'SCPH', 'SCPX', 'SCPY', 'SCPR', 'SCPZ', 'SCP#',
                                      'LEVL', 'RNGS', 'BNUS', 'WOBJ', 'LPAD', 'TOYS', 'TPTS', 'APTS']:
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        sectionData = fin.read(length)
                        print('  %s: 0x%06X:' % (magicStr, length))
                        hexdump(sectionData)
                    elif magicStr == 'DATA': # ASCII(?) Data, game/mission/etc text
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        sectionData = fin.read(length)
                        print('  %s: 0x%06X:' % (magicStr, length))
                        print_hex_dump(sectionData)
                        print_adat_decoded(sectionData)
                    # PAD always seems to be 4 bytes of 0 - ignore it
                    elif magicStr in ['PAD ']:
                        length = int.from_bytes(fin.read(4), byteorder='big')
                        print('  %s: 0x%06X:' % (magicStr, length))
                        fin.seek(length, 1)
                    else:
                        nextInt = int.from_bytes(fin.read(4), byteorder='big')
                        print('unknown magic: %s [%08X]' % (magicStr, nextInt))
                        dumping = False
                        return
            else:
                print('unknown top magic: ' + ''.join('{:02x}'.format(x) for x in magic) + ' "' + magicStr + '"')
                dumping = False
                return

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='Pilotwings 64 File System Dumper')
    ap.add_argument('file', help='File path of input')
    ap.add_argument('-s', '--start', dest='startOffset', type=auto_int, default=0x0DF5B0, help='Start offset of file system')
    ap.add_argument('-x', '--hex', dest='hexSize', type=auto_int, default=0x60, help='Size of hexdump for unparsed sections')
    args = ap.parse_args()
    pw64_dump_filesys(args.file, args.startOffset, args.hexSize)
