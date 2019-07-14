# Pilotwings 64 Tools
Tools and notes for hacking Pilotwings 64

Pilotwings 64 filesys dumper
----------------------------
Quick tool to iterate over the filesystem entries. See `-h`
```bash
$ ./pw64_filesys_dump.py
usage: pw64_filesys_dump.py [-h] [-s STARTOFFSET] [-x HEXSIZE] file
# dump table @ 0xDE720
$ ./pw64_filesys_dump.py -s 0xDE720 /path/to/pw64.u.z64
0x0DE720: FORM: 0x000E7C (end: 0x0DF5A4)
0x0DE728:   UVRM
0x0DE72C:   PAD : 0x000004
0x0DE738:   PAD : 0x000004
0x0DE744:   GZIP: 0x000E58: TABL/MIO0
0x0DF5A4: 00000000 [EOF]
# dump main filesystem @ 0x0DF5B0 (default). Redirect to file!
$ ./pw64_filesys_dump.py /path/to/pw64.u.z64 > /tmp/pw64_filesys_0df5b0.txt
```

n64split config
---------------
Current [n64split](https://github.com/queueRAM/sm64tools) configuration disassembles both kernel and app .text sections, 
dumps a couple RSP blobs, and extracts all the [MIO0](https://hack64.net/wiki/doku.php?id=super_mario_64:mio0) compressed blocks.
```bash
$ n64split -c n64split_pilotwings_64.u.yaml /path/to/pw64.u.z64

ROM split statistics:
Total decoded section size:  4A00E8/800000 (57.82%)
```

radare2 script
--------------
[radare2](https://github.com/radare/radare2) reverse engineering tools example usage with [r2dec](https://github.com/wargio/r2dec-js) decompiler
```c
$ r2 -n -i radare2_pilotwings_64.r2 /path/to/pw64.u.z64
[0x80200050]> pdd @linked_list_insert
/* r2dec pseudo code output */
void linked_list_insert () {
    t6 = *(a1);
    *((a0 + 1)) = a1;
    *(a0) = t6;
    v0 = *(a1);
    if (v0 != 0) {
        *((v0 + 1)) = a0;
    }
    *(a1) = a0;
    return;
}
```
