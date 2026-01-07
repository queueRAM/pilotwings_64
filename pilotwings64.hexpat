#pragma author queueRAM
#pragma description Pilot Wings 64 ImHex Pattern N64 ROM header and filesystem

#pragma endian big

import std.io;
import std.mem;

// --------- N64 ROM header ------------

enum CategoryCode : u8 {
  GamePak = 'N',
  Disk_64DD = 'D',
  Expandable_Game_Pak = 'C',
  Expandable_Game_64DD = 'E',
  Aleck64_Game_Pak = 'Z',
};

enum RegionCode : u8 {
  All = 'A',
  Brazil = 'B',
  China = 'C',
  Germany = 'D',
  North_America = 'E',
  France = 'F',
  Gateway_64_NTSC = 'G',
  Netherlands = 'H',
  Italy = 'I',
  Japan = 'J',
  Korea = 'K',
  Gateway_64_PAL = 'L',
  Canada = 'N',
  Europe = 'P',
  Spain = 'S',
  Australia = 'U',
  Scandinavia = 'W',
  Europe = 'X',
  Europe = 'Y',
  Europe = 'Z',
};

struct GameCode {
  CategoryCode categoryCode;
  char gameCode[2];
  RegionCode regionCode;
};

struct LibultraVersion {
  padding[2];
  u8 majorMinor;
  char revision;
}  [[format("libultra_u32")]];;

fn libultra_u32(auto v) {
    u8 major = v.majorMinor / 10;
    u8 minor = v.majorMinor % 10;
    return std::format("{}.{}{}", major, minor, v.revision);
};

struct N64Header {
  u32 PI_BSD_DOM1;
  u32 clockRate;
  u32 *bootAddress : u32;
  LibultraVersion libultraVersion;
  u64 checkCode;
  padding[8];
  char gameTitle[0x14];
  padding[7];
  GameCode gameCode;
  u8 romVersion;
};


// --------- Pilot Wings 64 file system ------------

// PAD always seems to be 4 bytes of 0
struct PAD {
    u32 length;
    u8 data[length];
};

// TODO: special case UVSQ version of COMM
struct COMM {
    u32 length;
    u8 data[length];
};

// not actually gzip, but MIO0 container
struct GZIP {
    u32 compLength;
    char decompType[4];
    u32 decompLength;
    u8 compData[compLength - 8];
};

// strings found in NAME, INFO, JPTX
struct PW64_String {
    u32 length;
    char info[length];
};

// generic handler for lengths that are not yet parsed
struct TBD {
    u32 length;
    u8 data[length];
};

struct Entry {
    char tag[4];
    // no lengths associated with these tags, so not explicitly matched:
    // "UVSY" | "UVEN" | "UVLT" | "UVTR" | "UVLV" | "UVSQ" | "UVTP" | "UVMD" |
    // "UVCT" | "UVTX" | "UVAN" | "UVFT" | "UPWL" | "SPTH" | "UPWT" | "ADAT" | 
    // "3VUE" | "PDAT" | "UVBT" | "UVSX" | "UVRM"
    match (tag) {
        ("PAD "): PAD entry;
        ("COMM"): COMM entry;
        ("GZIP"): GZIP entry;
        ("NAME" | "INFO" | "JPTX"): PW64_String entry;
        ("PART" | "STRG" | "FRMT" | "ESND" | "TPAD" | "CNTG" | "HOPD" | "LWIN" | 
         "LSTP" | "TARG" | "FALC" | "BALS" | "HPAD" | "BTGT" | "THER" | "PHTS" |
         "SIZE" | "QUAT" | "XLAT" | "PHDR" | "RHDR" | "PPOS" | "RPKT" | ".CTL" | 
         ".TBL" | "SCPP" | "SCPH" | "SCPX" | "SCPY" | "SCPR" | "SCPZ" | "SCP#" |
         "LEVL" | "RNGS" | "BNUS" | "WOBJ" | "LPAD" | "TOYS" | "TPTS" | "APTS"): TBD entry;
    }
} [[name(std::format("Entry({})", tag))]];

struct PW64_FORM {
    u64 defStart = $;
    char tag[4];
    u32 length;
    Entry entries[while(($ - defStart) < length)];
};


N64Header N64Header @ 0x00;

PW64_FORM forms[while(std::mem::read_unsigned($, 4, std::mem::Endian::Big) != 0)] @ 0xDF5B0;