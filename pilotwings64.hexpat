#pragma description Pilotwings 64 ImHex Pattern | N64 ROM header and PW64 filesystem
#pragma author queueRAM

#pragma endian big

import std.io;
import std.mem;
import std.string;

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


// --------- Pilotwings 64 filesystem ------------

// --- common types
using f32 = be float;

struct Vec3f {
    f32 x, y, z;
};

struct Mtx4F {
    f32 m[16];
};

// --- UV kernel types
struct UVSY {
    f32 unk0;
    u16 uvVersion;
    u16 UVMD;
    u16 UVCT;
    u16 UVTX;
    u16 UVEN;
    u16 UVLT;
    u16 UVTR;
    u16 UVSQ;
    u16 UVLV;
    u16 UVAN;
    u16 UVFT;
    u16 UVBT;
    u16 unk1C;
    u16 UVSX;
    u16 UVTP;
    u16 unk22;
    padding[4];
} [[static]]; // size = 0x28 (only 0x24 allocated in code)


struct UVEN_Models {
    u16 modelId;
    u8 flag;
} [[static]]; // size = 0x3

struct UVEN_Data {
    u8 screenR;
    u8 screenG;
    u8 screenB;
    u8 screenA;
    u8 fogR;
    u8 fogG;
    u8 fogB;
    u8 fogA;
    u8 unk8;
    u8 unk9;
    u8 unkA;
    u8 unkB;
    u8 padC[8];
    f32 unk14;
    f32 unk18;
    u8 unk1C;
    u8 pad1D[17];
    u8 unk2E;
    u8 pad2F;
    u32 ptr30;
    u8 count;
    padding[3];
    u32 ptr38;
} [[static]]; // size = 0x3C

struct UVEN {
    u8 count;
    UVEN_Models models[count];
    UVEN_Data data;
};


struct UVTR_Tile {
    u8 tileType;
    if (tileType != 0) {
        Mtx4F mat;
        u8 unk44;
        u16 contIdx;
    }
}; // size = (tileType == 0) ? 0x01 : 0x14

struct UVTR {
    f32 unk0;
    f32 unk4;
    f32 unk8;
    f32 unkC;
    f32 unk10;
    f32 unk14;
    u8 unk18;
    u8 unk19;
    f32 unk1C;
    f32 unk20;
    f32 unk24;
    UVTR_Tile tiles[unk18 * unk19];
}; // size = 0x28 + variable tiles


struct UVLV {
    u16 terraCount;
    u16 terraIds[terraCount];
    u16 lightCount;
    u16 lightIds[lightCount];
    u16 environmentCount;
    u16 environmentIds[environmentCount];
    u16 modelCount;
    u16 modelIds[modelCount];
    u16 contourCount;
    u16 countourIds[contourCount];
    u16 textureCount;
    u16 textureIds[textureCount];
    u16 sequenceCount;
    u16 sequenceIds[sequenceCount];
    u16 animationCount;
    u16 animationIds[animationCount];
    u16 fontCount;
    u16 fontIds[fontCount];
    u16 blitCount;
    u16 blitIds[blitCount];
};


struct UVSQ_Unk4 {
    u16 unk0;
    f32 unk4;
} [[static]]; // size = 0x6

struct UVSQ {
    u8 count;
    UVSQ_Unk4 unk4[count];
    u8 unk8;
    u8 unk9;
    f32 unkC;
};


struct UVTP_Unk {
    u16 unk4;
    u16 unk8;
} [[static]]; // size = 0x4

struct UVTP {
    u16 count;
    UVTP_Unk unk[count];
};


struct TBD_ {
    u8 comm[parent.length];
};


// PW64 Level types
enum WOBJType : u8 {
    Windsock = 0x00,
    WindTurbine = 0x01,
};

struct WOBJ {
    Vec3f position;
    WOBJType wobjType;
    padding[3];
};

struct BALS {
    Vec3f position;
    padding[20];
    u8 type;
    padding[15];
    float scale;
    padding[0x34];
};

struct BNUS {
    Vec3f position;
    u32 unkC;
    u32 unk10;
    u32 unk14;
    u32 unk18;
    u32 unk1C;
};

struct BTGT {
    Vec3f position;
    Vec3f angle;
    u8 unk18;
    padding[7];
};

struct HPAD {
    Vec3f position;
    Vec3f angle;
    padding[8];
    float unk20;
    padding[0x40-0x24];
};

struct LPAD {
    Vec3f position;
    Vec3f angle;
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

struct TARG {
    Vec3f position;
    Vec3f angle;
    u8 type;
    u8 unk19;
    padding[6];
};

struct TPAD {
    Vec3f position;
    Vec3f angle;
    padding[0x10];
    u8 onGround;
    padding[3];
    float unk2C;
};

struct HOPD {
    Vec3f position;
    padding[7];
    u8 unk13;
    float scale;
    float height;
    padding[4];
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

struct THER {
    float x;
    float y;
    float z;
    float scale;
    float height;
    float unk14;
    float unk18;
    float unk1C;
    float unk20;
    float unk24;
};

struct TPTS {
    u8 unk0;
    padding[3];
    Vec3f position;
    float unk10;
    float unk14;
    s32 unk18;
    float unk1C;
    s32 unk20;
    float unk24;
    Vec3f unk28;
};

// strings found in NAME, INFO, JPTX
struct PW64_String {
    u32 length;
    char info[length];
};


// format PW64 u16 strings as ASCII representation
fn pw64ToAscii(ref auto val) {
    str result;
    for (u32 i = 0, i < sizeof(val) / 2, i += 1) {
        u16 v = val[i];
        if (v >= 0x60 && v <= 0xBF) { // [0x60-0xBF]: bold versions of [0x00-0x5F]
            v -= 0x60;
        }
        match (v) {
            (0x00 ... 0x09): result += char('0' + v);
            (0x0A ... 0x23): result += char('A' + v - 0xA);
            (0x24 ... 0x3D): result += char('a' + v - 0x24);
            (0x3E): result += "-";
            (0x3F): result += "#";
            (0x40): result += "<";
            (0x41): result += ">";
            (0x42): result += " ";
            (0x43): result += "\"";
            (0x44): result += "(";
            (0x45): result += ")";
            (0x46): result += "*";
            (0x47): result += "&";
            (0x48): result += ",";
            (0x49): result += ".";
            (0x4A): result += "/";
            (0x4B): result += "!";
            (0x4C): result += "?";
            (0x4D): result += "'";
            (0x4E): result += "#";
            (0x4F): result += ":";
            (0x50 ... 0x59): result += std::format("{}", v - 0x50);
            (0xD4): result += "%";
            (0xFD): result += " "; // actually "\t"
            (0xFE): result += "\n";
            (0xFF): result += "\0";
            (_): result += ".";
        }
    }
    return result;
};

struct ADAT {
    char tag[4];
    u32 length;
    match (tag) {
        ("PAD "): u8 pad[length] [[hidden]];
        ("SIZE"): u8 size[length];
        ("NAME"): char name[length];
        ("DATA"): u16 data[length / 2] [[format("pw64ToAscii")]];
        (_): u8 data[length]; // catch all for things like "SIZE"
    }
};


// templated handler for UV FORM data
struct UV<T, auto Align> {
    char tag[4];
    u32 length;
    match (tag) {
        ("PAD "): u8 pad[length] [[hidden]];
        ("COMM"): T comm;
        ("GZIP"): {
            char comm[4];
            u32 dLength;
            u8 compData[length - 8]; // length includes COMM and dLength
        }
        (_): u8 data[length]; // catch all for things like "PART" in UNAN or "LEVL" in UPWL
    }
    if (Align) {
        padding[while($ % 8 != 0)];
    }
};


struct FORM {
    char form[4];
    u32 length;
    const u64 TagStart = $;
    char tag[4];
    match (tag) {
        // UV tags
        ("UVSY"): UV<UVSY, true> entries[while(($ - TagStart) < length)];
        ("UVEN"): UV<UVEN, true> entries[while(($ - TagStart) < length)];
        ("UVTR"): UV<UVTR, true> entries[while(($ - TagStart) < length)];
        ("UVLV"): UV<UVLV, true> entries[while(($ - TagStart) < length)];
        ("UVSQ"): UV<UVSQ, true> entries[while(($ - TagStart) < length)];
        ("UVTP"): UV<UVTP, true> entries[while(($ - TagStart) < length)];
        ("UVMD"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // pure GZIP
        ("UVCT"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // pure GZIP
        ("UVTX"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // pure GZIP
        ("UVBT"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // pure GZIP
        ("UVAN"): UV<TBD_, false> entries[while(($ - TagStart) < length)];
        ("UVFT"): UV<u8, false> entries[while(($ - TagStart) < length)];
        ("UPWL"): UV<u8, false> entries[while(($ - TagStart) < length)]; // TODO: types for LEVL/LPAD/etc.
        ("SPTH"): UV<u8, false> entries[while(($ - TagStart) < length)]; // TODO: types for SCPP/SCPH/etc.
        ("UPWT"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // TODO: types for JPTX/NAME/INFO
        ("ADAT"): ADAT entries[while(($ - TagStart) < length)]; // TODO: types for SIZE/NAME/DATA
        ("3VUE"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // TODO: types for QUAT/XLAT
        ("PDAT"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // TODO: types for QUAT/XLAT
        ("UVSX"): UV<TBD_, false> entries[while(($ - TagStart) < length)]; // TODO: types for .CTL/.TBL
    }
} [[name(std::format("{}", tag))]];


// --------- Header
N64Header N64Header @ 0x00;

// --------- Filesystem
FORM uvsy @ 0xDF5B0;
FORM uven @ 0xDF5F8;
// ignore UVLT @ 0xDFD70 because it is empty
FORM uvtr @ 0xDFD88;
FORM uvlv @ 0xE2028;
FORM uvsq @ 0xE4FA8;
FORM uvtp @ 0xE5030;
FORM uvmd[363] @ 0xE5138;
FORM uvct[101] @ 0x1BB0AC;
FORM uvtx[463] @ 0x240100;
FORM uvan[115] @ 0x3085DC;
FORM uvft[9] @ 0x32C3F8;
FORM upwl[4] @ 0x33020C;
FORM spth0 @ 0x342B7C;
FORM upwt[61] @ 0x342E2C;
FORM adat0 @ 0x35C08C;
FORM spth1[5] @ 0x36E214;
FORM vue3[12] @ 0x36E754;
FORM pdat[25] @ 0x37F434;
FORM spth2[2] @ 0x44C774;
FORM uvbt[102] @ 0x44D494;
FORM uvsx @ 0x4B577C;
