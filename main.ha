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
use debug;

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

type CPU = struct {
    pc: u16,// Program Counter
    sp: u8, // Stack Pointer

    // Registers
    ac: u8,
    x:  u8,
    y:  u8,

    //  Status Register Flags:
    C: bool, // Carry
    Z: bool, // Zero
    I: bool, // Interrupt Disable
    D: bool, // Decimal Mode
    B: bool, // Break Command
    O: bool, // Overflow
    N: bool, // Negative
};

let cpu = CPU {...};

fn cpu_reset() void = {
    cpu.pc = 0xFFFC;
    cpu.sp = 0xFF;
    cpu.ac = 0;
    cpu.x  = 0;
    cpu.y  = 0;

    mem_init();
};

fn fetch_byte() u8 = {
    assert(cpu.pc < MAX_MEM);
    let data: u8 = mem[cpu.pc];
    cpu.pc += 1;
    return data;
};

fn fetch_word() u16 = {
    // 6502 is little endian
    assert(cpu.pc < MAX_MEM);
    let data: u16 = mem[cpu.pc];
    cpu.pc += 1;

    // let mem_data: u16 = mem[cpu.pc];
    // data |= mem_data << 8;
    data |= (mem[cpu.pc]: u16 << 8);
    cpu.pc += 1;

    return data;
};

// fn write_word(value: u16, address: u8) void = {
//     mem[address] = (value & 0xFF): u8;
//     mem[address + 1] = (value >> 8): u8;
// };

// TODO: need to test the stack functions properly
fn sp_to_address() u16 = {
    return 0x0100 | cpu.sp: u16;
};

fn stack_push_byte(value: u8) void = {
    // sp register points to the next free byte of stack space
    // store value at current free location
    let address: u16 = sp_to_address();
    mem[address] = value;
    // post decrement the stack pointer
    // fmt::printfln("Pushed byte to stack: ${:X}", value)!;
    cpu.sp -= 1;
};

fn stack_push_word(value: u16) void = {
    stack_push_byte((value >> 8): u8);  // Push high byte first
    stack_push_byte(value: u8);         // Then push low byte
    // fmt::printfln("Pushed word to stack: ${:X}", value)!;
    return;
};

fn stack_pop_byte() u8 = {
    // increment the stack pointer
    cpu.sp += 1;
    // now stack pointer points at the last pushed byte
    // pull data from stack
    let data: u8 = mem[sp_to_address()];
    // TODO: set byte to null?
    // fmt::printfln("Popped byte from stack: ${:X}", data)!;
    return data;
};

fn stack_pop_word() u16 = {
    let data: u16 = 0;
    data |= stack_pop_byte(): u16;      // Pop low byte first
    data |= stack_pop_byte(): u16 << 8; // Then pop high byte
    // fmt::printfln("Popped word from stack: ${:X}", data)!;
    return data;
};

// CPU Instructions
type ins = enum u8 {
    // Load/Store operations
    // LDA - Load Accumulator
    lda_im  = 0xA9, // Immediate Mode
    lda_zp  = 0xA5, // Zero Page
    lda_zpx = 0xB5, // Zero Page, X
    // Jumps and Calls
    jsr     = 0x20, // jump to subroutine
    rts     = 0x60, // return from subroutine
};

fn cpu_lda_set_status() void = {
    cpu.Z = (cpu.ac == 0);  // set if ac == 0
    cpu.N = (cpu.ac & 0b10000000) > 0;  // set if bit 7 of a is set
};

fn cpu_execute(cycles: int) void = {
    // jump to execution address of cold reset
    cpu.pc = fetch_word();

    for (cycles > 0) {
        let ins: u8 = fetch_byte();

        switch (ins) {
        case ins::lda_im =>
            let value: u8 = fetch_byte();
            cpu.ac = value;
            cpu_lda_set_status();
            cycles -= 2;
            fmt::printfln("ins::lda_im, ${:X}", value)!;

        case ins::jsr =>
            let subroutineAddr: u16 = fetch_word();
            // push (address - 1) of return point onto stack
            stack_push_word(cpu.pc - 1);
            // set program counter to target memory address
            cpu.pc = subroutineAddr;
            cycles -= 6;
            fmt::printfln("ins::jsr, ${:X}", subroutineAddr)!;

        case ins::rts =>
            // pull return address from the stack
            let returnAddress: u16 = stack_pop_word();
            // set program counter to return address + 1
            cpu.pc = returnAddress + 1;
            cycles -= 6;
            fmt::printfln("ins::rts (popped from stack: ${:X})", returnAddress)!;

        case =>
            fmt::errorfln("Instruction unimplemented! ${:X}", ins)!;
            break;
        };
    };
};

export fn main() void = {
    fmt::println("6502 Emulator has started lol")!;
    cpu_reset();

    // start - inline program
    // Set reset vector to point to program start
    mem[0xFFFC] = 0x43;
    mem[0xFFFD] = 0xFE;

    mem[0xFE43] = ins::jsr;
    mem[0xFE44] = 0x52;
    mem[0xFE45] = 0x42;
    mem[0xFE46] = ins::lda_im;
    mem[0xFE47] = 0x96;

    mem[0x4252] = ins::lda_im;
    mem[0x4253] = 0x69;
    mem[0x4254] = ins::rts;
    // end - inline program

    cpu_execute(16);
    fmt::printfln("CPU Register AC: ${:X}", cpu.ac)!;
};
