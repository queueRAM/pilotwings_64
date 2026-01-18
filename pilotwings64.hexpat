#pragma author queueRAM
#pragma description Pilotwings64 ImHex Pattern N64 ROM header and filesystem

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


// --------- Pilotwings 64 file system ------------
struct Vec3f {
    float x, y, z;
};

enum WOBJType : u8 {
    Windsock = 0x00,
    WindTurbine = 0x01,
};

struct WOBJ {
    Vec3f position;
    WOBJType wobjType;
    padding[3];
};

struct LPAD {
    Vec3f position;
    float heading;
    padding[8];
};

struct BNUS {
    Vec3f position;
    u32 unkC;
    u32 unk10;
    u32 unk14;
    u32 unk18;
    u32 unk1C; // TODO is this length 0x1C or 0x20?
};

struct THER {
    Vec3f position;
    float scale;
    float height;
    u32 unk14;
    float unk18;
};

struct RNGS {
    Vec3f position;
    Vec3f angle;
    padding[5];
    u8 other;
    padding[0x36];
    u8 size;
    padding[0x1B];
    u8 axis;
    padding[1];
    u8 special;
    padding[0x11];
};

struct BALS {
    Vec3f position;
    padding[20];
    u8 type;
    padding[15];
    float scale;
    padding[0x34];
};

struct TARG {
    Vec3f position;
    Vec3f angle;
    u8 type;
    u8 unk19;
    padding[6];
};

struct HPAD {
    Vec3f position;
    Vec3f angle;
    padding[8];
    float unk20;
    padding[0x40-0x24];
};

struct LSTP {
    Vec3f upperLeft;
    Vec3f lowerRight;
    padding[4];
    u8 unk1C;
    padding[3];
    float unk20;
    padding[4];
};

struct TPAD {
    Vec3f position;
    Vec3f angle;
    padding[0x10];
    u8 onGround;
    padding[3];
    float unk2C;
};

struct BTGT {
    Vec3f position;
    Vec3f angle;
    u8 unk18;
    padding[7];
};

struct HOPD {
    Vec3f position;
    padding[7];
    u8 unk13;
    float scale;
    float height;
    padding[4];
};

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
        ("NAME" | "INFO" | "JPTX" | "STRG"): PW64_String entry;
        ("WOBJ"): {u32 length; WOBJ wobj[length / sizeof(WOBJ)];}
        ("LPAD"): {u32 length; LPAD lpad[length / sizeof(LPAD)];}
        ("BNUS"): {u32 length; BNUS bnus[length / sizeof(BNUS)];}
        ("THER"): {u32 length; THER ther[length / sizeof(THER)];}
        //("RNGS"): {u32 length; RNGS rngs[length / sizeof(RNGS)]; u32 unk;}
        ("RNGS"): TBD entry; // some RNGS have 4 bytes at end. need to improve struct
        ("BALS"): {u32 length; BALS bals[length / sizeof(BALS)];}
        ("TARG"): {u32 length; TARG targ[length / sizeof(TARG)];}
        ("CNTG"): {u32 length; TARG cntg[length / sizeof(TARG)];}
        ("HPAD"): {u32 length; HPAD hpad[length / sizeof(HPAD)];}
        ("LSTP"): {u32 length; LSTP lstp[length / sizeof(LSTP)];}
        ("TPAD"): {u32 length; TPAD tpad[length / sizeof(TPAD)];}
        ("BTGT"): {u32 length; BTGT btgt[length / sizeof(BTGT)];}
        ("HOPD"): {u32 length; HOPD hopd[length / sizeof(HOPD)];}
        ("PART" | "FRMT" | "ESND" | "LWIN" | "FALC" | "PHTS" | "SIZE" | "QUAT" |
         "XLAT" | "PHDR" | "RHDR" | "PPOS" | "RPKT" | ".CTL" | ".TBL" | "LEVL" |
         "SCPP" | "SCPH" | "SCPX" | "SCPY" | "SCPR" | "SCPZ" | "SCP#" | "TOYS" |
         "TPTS" | "APTS"): TBD entry;
    }
} [[name(std::format("{}", tag))]];

struct PW64_FORM {
    u64 defStart = $;
    char tag[4];
    u32 length;
    Entry entries[while(($ - defStart) < length)];
};

// --------- Declarations

N64Header N64Header @ 0x00;

PW64_FORM form1[while(std::mem::read_unsigned($, 4, std::mem::Endian::Big) != 0)] @ 0xDE720;
PW64_FORM form2[while(std::mem::read_unsigned($, 4, std::mem::Endian::Big) != 0)] @ 0xDF5B0;