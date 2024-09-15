//
// Making an emulator?
// 6502 Processor

// Links:
// ----------------------------
// https://youtu.be/qJgsuQoy9bc
// https://github.com/davepoo/6502Emulator
// https://sta.c64.org/cbm64mem.html
//
// https://www.nesdev.org/wiki/NES_reference_guide
//
// -> 6502
// http://6502.org/users/obelisk/6502/registers.html
// ----------------------------
//
// 14 sept 2024:
// ------------
// https://www.reddit.com/r/C_Programming/comments/ojha2c/a_minimal_and_beginner_friendly_6502_emulator/
// -> https://github.com/f0lg0/6502
//
// Path to my hare std library
// /usr/local/src/hare/stdlib
use fmt;

// Note for noob sareb:
// u16 is 16 bits - a Word
// u8 is 8 bits - a Byte

def MAX_MEM: u32 = 1024 * 64;
let mem: [MAX_MEM]u8 = [0...];

fn mem_init() void = {
    for (let i=0z; i < len(mem); i += 1)
        mem[i] = 0;
    return;
};

fn mem_write_word(cycles: *int, value: u16, address: u8) void = {
    mem[address] = (value & 0xFF): u8;
    mem[address + 1] = (value >> 8): u8;
    *cycles -= 2;
};

type CPU = struct {
    pc: u16,// Program Counter
    sp: u8, // Stack Pointer

    // Registers
    ac: u8,
    x:  u8,
    y:  u8,
    //
    //  Status Register:
    //  ================
    //  bit 0:  Carry
    //  bit 1:  Zero
    //  bit 2:  Interrupt
    //  bit 3:  Decimal
    //  bit 4:  Break
    //  bit 5:  0 - Unused
    //  bit 6:  Overflow
    //  bit 7:  Negative
    //
    // sr: u8,
    // FIXME: bool = bad? i think..? lol
    C: bool,
    Z: bool,
    I: bool,
    D: bool,
    B: bool,
    U: bool,
    O: bool,
    N: bool,
};
// type srFlag = enum {
//     C = 0,  // Carry
//     Z,  // Zero
//     I,  // Interrupt
//     D,  // Decimal
//     B,  // Break
//     U,  // 0 - Unused
//     O,  // Overflow
//     N,  // Negative
// };

let cpu = CPU {...};

fn cpu_reset() void = {
    cpu.pc = 0xfffc;
    cpu.sp = 0x01;
    cpu.ac = 0;
    cpu.x = 0;
    cpu.y = 0;

    mem_init();
};

fn cpu_fetch_byte(cycles: *int) u8 = {
    assert(cpu.pc < MAX_MEM);
    let data: u8 = mem[cpu.pc];
    cpu.pc += 1;
    *cycles -= 1;
    return data;
};

fn cpu_fetch_word(cycles: *int) u16 = {
    // 6502 is little endian
    assert(cpu.pc < MAX_MEM);
    let data: u16 = mem[cpu.pc];
    cpu.pc += 1;

    let mem_data: u16 = mem[cpu.pc];
    data |= mem_data << 8;
    cpu.pc += 1;

    *cycles -= 2;
    return data;
};

// opcodes and stuffs
type ins = enum u8 {
    lda_im  = 0xA9,
    lda_zp  = 0xA5,
    lda_zpx = 0xB5,
    jsr     = 0x20,
};

fn cpu_lda_set_status() void = {
    cpu.Z = (cpu.ac == 0);  // set if ac == 0
    cpu.N = (cpu.ac & 0b10000000) > 0;  // set if bit 7 of a is set
};

fn cpu_execute(cycles: int) void = {
    for (cycles > 0) {
        let ins: u8 = cpu_fetch_byte(&cycles);
        // switch (ins) {
        // case _ => -----;
        // };
        switch (ins) {
        case ins::lda_im =>
            let value: u8 = cpu_fetch_byte(&cycles);
            cpu.ac = value;
            cpu_lda_set_status();
            fmt::printfln("ins::lda_im, {:x}", value)!;

        case ins::jsr =>
            let subAddr: u16 = cpu_fetch_word(&cycles);
            mem_write_word(&cycles, cpu.pc - 1, cpu.sp);
            cpu.sp += 1;
            cpu.pc = subAddr;
            cycles -= 1;
            fmt::printfln("ins::jsr, {:x}", subAddr)!;
        case =>
            fmt::errorfln("Instruction unimplemented! {:x}", ins)!;
        };
    };
};

export fn main() void = {
    fmt::println("6502 Emulator (NES) has started lol")!;
    cpu_reset();

    // start - inline program
    mem[0xFFFC] = ins::jsr;
    mem[0xFFFD] = 0x42;
    mem[0xFFFE] = 0x42;
    mem[0x4242] = ins::lda_im;
    mem[0x4243] = 0x84;
    // end - inline program

    cpu_execute(8);
    fmt::printfln("CPU Register AC: {:x}", cpu.ac)!;
};
