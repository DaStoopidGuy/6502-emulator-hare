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
// very nice website for instruction set reference
// https://www.masswerk.at/6502/6502_instruction_set.html
//
// https://www.nesdev.org/6502_cpu.txt
//
// Local path to obelisk 6502 guide (press gx in vim to open in browser)
// --------------------------------
// file:///home/sarebjay/code/extern/www.nesdev.org/obelisk-6502-guide/instructions.html
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
    assert(cpu.pc < MAX_MEM, "Program Counter must not overflow MAX MEM");
    let data: u8 = mem[cpu.pc];
    cpu.pc += 1;
    return data;
};

fn fetch_word() u16 = {
    // 6502 is little endian
    assert(cpu.pc < MAX_MEM, "Program Counter must not overflow MAX MEM");
    let data: u16 = fetch_byte();

    data |= fetch_byte(): u16 << 8;

    return data;
};

fn read_byte(address: u16) u8 = {
    assert(address < MAX_MEM, "Address must not overflow MAX MEM");
    let data: u8 = mem[address];
    return data;
};

fn read_word(address: u16) u16 = {
    let data: u16 = read_byte(address);
    data |= read_byte(address + 1): u16 << 8;
    return data;
};

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
    lda_im   = 0xA9, // Immediate Mode
    lda_zp   = 0xA5, // Zero Page
    lda_zpx  = 0xB5, // Zero Page, X
    lda_abs  = 0xAD, // Absolute
    lda_absx = 0xBD, // Absoulte, X
    lda_absy = 0xB9, // Absolute, Y
    lda_indx = 0xA1, // Indirect, X
    lda_indy = 0xB1, // Indirect, Y
    // LDX - Load X Register
    ldx_im   = 0xA2,
    ldx_zp   = 0xA6,
    ldx_zpy  = 0xB6,
    ldx_abs  = 0xAE,
    ldx_absy = 0xBE,
    // LDY - Load Y Register
    ldy_im   = 0xA0,
    ldy_zp   = 0xA4,
    ldy_zpx  = 0xB4,
    ldy_abs  = 0xAC,
    ldy_absx = 0xBC,
    // STA - Store Accumulator
    sta_zp   = 0x85,
    sta_zpx  = 0x95,
    sta_abs  = 0x8D,
    sta_absx = 0x9D,
    sta_absy = 0x99,
    sta_indx = 0x81,
    sta_indy = 0x91,
    // Store X Register
    stx_zp  = 0x86,
    stx_zpy = 0x96,
    stx_abs = 0x8E,
    // Store Y Register
    sty_zp  = 0x84,
    sty_zpx = 0x94,
    sty_abs = 0x8C,
    // Jumps and Calls
    jsr     = 0x20, // jump to subroutine
    rts     = 0x60, // return from subroutine
};

fn cpu_set_status_load_register(register: u8) void = {
    cpu.Z = (register == 0);
    cpu.N = (register & 0b10000000) > 0;
};

fn cpu_execute(cycles: int) int = {
    let cyclesRequested: int = cycles;
    // jump to execution address of cold reset
    cpu.pc = fetch_word();

    for (cycles > 0) {
        let ins: u8 = fetch_byte();

        switch (ins) {
            // ----------------------
            // LDA - Load Accumulator
            // ----------------------
        case ins::lda_im =>
            let value: u8 = fetch_byte();
            cpu.ac = value;
            cpu_set_status_load_register(cpu.ac);
            cycles -= 2;
            fmt::printfln("ins::lda_im, ${:X}", value)!;

        case ins::lda_zp =>
            let address: u8 = fetch_byte();
            cpu.ac = mem[address: u16];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 3;
            fmt::printfln("ins::lda_zp, ${:X}", address)!;

        case ins::lda_zpx =>
            // take zero page address from instruction
            let address: u8 = fetch_byte();
            // add current value of X register to it
            address += cpu.x;
            // load accumulator from the zeropage address
            cpu.ac = mem[address: u16];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 4;
            fmt::printfln("ins::lda_zpx, ${:X}", address)!;

        case ins::lda_abs =>
            let address: u16 = fetch_word();
            cpu.ac = mem[address];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 4;
            fmt::printfln("ins::lda_abs, ${:X}", address)!;

        case ins::lda_absx =>
            let address: u16 = fetch_word();
            address += cpu.x;

            // check if addition wraps around, or "page crossed"
            // if the low byte is less than index register X,
            // then it means page was crossed, additional cycle
            if (address & 0x00FF < cpu.x) cycles -= 1;

            cpu.ac = mem[address];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 4;
            fmt::printfln("ins::lda_absx, ${:X}", address)!;

        case ins::lda_absy =>
            let address: u16 = fetch_word();
            address += cpu.y;
            if (address & 0x00FF < cpu.x) cycles -= 1;

            cpu.ac = mem[address];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 4;
            fmt::printfln("ins::lda_absy, ${:X}", address)!;

        case ins::lda_indx =>
            let address: u8 = fetch_byte();
            address += cpu.x;
            // this points to the least significant byte of the
            // target address
            let targetAddress: u16 = read_word(address: u16 & 0x00FF);
            cpu.ac = mem[targetAddress];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 6;
            fmt::printfln("ins::lda_indx, ${:X}", address)!;

        case ins::lda_indy =>
            let address: u8 = fetch_byte();
            // above zeropage address contains the least
            // significant byte of the target address
            let targetAddress: u16 = read_word(address: u16);
            targetAddress += cpu.y;
            if (targetAddress & 0x00FF < cpu.y) cycles -= 1;

            cpu.ac = mem[targetAddress];
            cpu_set_status_load_register(cpu.ac);
            cycles -= 5;
            fmt::printfln("ins::lda_indy, ${:X}", address)!;

            // ---------------------
            // LDX - Load X Register
            // ---------------------
        case ins::ldx_im =>
            let value: u8 = fetch_byte();
            cpu.x = value;
            cpu_set_status_load_register(cpu.x);
            cycles -= 2;
            fmt::printfln("ins::ldx_im, ${:X}", value)!;

        case ins::ldx_zp =>
            let address: u8 = fetch_byte();
            cpu.x = mem[address: u16];
            cpu_set_status_load_register(cpu.x);
            cycles -= 3;
            fmt::printfln("ins::ldx_zp, ${:X}", address)!;

        case ins::ldx_zpy =>
            let address: u8 = fetch_byte();
            address += cpu.y;
            cpu.x = mem[address: u16];
            cpu_set_status_load_register(cpu.x);
            cycles -= 4;
            fmt::printfln("ins::ldx_zpy, ${:X}", address)!;

        case ins::ldx_abs =>
            let address: u16 = fetch_word();
            cpu.x = mem[address];
            cpu_set_status_load_register(cpu.x);
            cycles -= 4;
            fmt::printfln("ins::ldx_abs, ${:X}", address)!;

        case ins::ldx_absy =>
            let address: u16 = fetch_word();
            address += cpu.y;
            if (address & 0x00FF < cpu.y) cycles -= 1;
            cpu.x = mem[address];
            cpu_set_status_load_register(cpu.x);
            cycles -= 4;
            fmt::println("ins::ldx_absy, ${:X}", address)!;

            // ---------------------
            // LDY - Load Y Register
            // ---------------------
        case ins::ldy_im =>
            let value: u8 = fetch_byte();
            cpu.y = value;
            cpu_set_status_load_register(cpu.y);
            cycles -= 2;
            fmt::printfln("ins::ldy_im, ${:X}", value)!;

        case ins::ldy_zp =>
            let address: u8 = fetch_byte();
            cpu.y = mem[address: u16];
            cpu_set_status_load_register(cpu.y);
            cycles -= 3;
            fmt::printfln("ins::ldy_zp, ${:X}", address)!;

        case ins::ldy_zpx =>
            let address: u8 = fetch_byte();
            address += cpu.x;
            cpu.y = mem[address];
            cpu_set_status_load_register(cpu.y);
            cycles -= 4;
            fmt::printfln("ins::ldy_zpx, ${:X}", address)!;

        case ins::ldy_abs =>
            let address: u16 = fetch_word();
            cpu.y = mem[address];
            cpu_set_status_load_register(cpu.y);
            cycles -= 4;
            fmt::printfln("ins::ldy_abs, ${:X}", address)!;

        case ins::ldy_absx =>
            let address: u16 = fetch_word();
            address += cpu.x;
            if (address & 0x00FF < cpu.x) cycles -= 1;
            cpu.y = mem[address];
            cpu_set_status_load_register(cpu.y);
            cycles -= 4;
            fmt::printfln("ins::ldy_absx, ${:X}", address)!;

            // -----------------------
            // STA - Store Accumulator
            // -----------------------
        case ins::sta_zp =>
            let address: u8 = fetch_byte();
            mem[address: u16] = cpu.ac;
            cycles -= 3;
            fmt::printfln("ins::sta_zp, ${:X}", address)!;

        case ins::sta_zpx =>
            let address: u8 = fetch_byte();
            address += cpu.x;
            mem[address: u16] = cpu.ac;
            cycles -= 4;
            fmt::printfln("ins::sta_zpx, ${:X}", address)!;

        case ins::sta_abs =>
            let address: u16 = fetch_word();
            mem[address] = cpu.ac;
            cycles -= 4;
            fmt::printfln("ins::sta_abs, ${:X}", address)!;

        case ins::sta_absx =>
            let address: u16 = fetch_word();
            address += cpu.x;
            mem[address] = cpu.ac;
            cycles -= 5;
            fmt::printfln("ins::sta_absx, ${:X}", address)!;

        case ins::sta_absy =>
            let address: u16 = fetch_word();
            address += cpu.y;
            mem[address] = cpu.ac;
            cycles -= 5;
            fmt::printfln("ins::sta_absy, ${:X}", address)!;

        case ins::sta_indx =>
            let address: u8 = fetch_byte();
            address += cpu.x;
            let targetAddress = read_word(address: u16);
            mem[targetAddress] = cpu.ac;
            cycles -= 6;
            fmt::printfln("ins::sta_indx, ${:X}", address)!;

        case ins::sta_indy =>
            let address: u8 = fetch_byte();
            let targetAddress: u16 = read_word(address: u16);
            targetAddress += cpu.y;
            mem[targetAddress] = cpu.ac;
            cycles -= 6;
            fmt::printfln("ins::sta_indy, ${:X}", address)!;

            // ----------------
            // Store X Register
            // ----------------
        case ins::stx_zp =>
            let address: u8 = fetch_byte();
            mem[address: u16] = cpu.x;
            cycles -= 3;
            fmt::printfln("ins::stx_zp, ${:X}", address)!;

        case ins::stx_zpy =>
            let address: u8 = fetch_byte();
            address += cpu.y;
            mem[address: u16] = cpu.x;
            cycles -= 4;
            fmt::printfln("ins::stx_zpy, ${:X}", address)!;

        case ins::stx_abs =>
            let address: u16 = fetch_word();
            mem[address] = cpu.x;
            cycles -= 4;
            fmt::printfln("ins::stx_abs, ${:X}", address)!;

            // ----------------
            // Store Y Register
            // ----------------
        case ins::sty_zp =>
            let address: u8 = fetch_byte();
            mem[address: u16] = cpu.y;
            cycles -= 3;
            fmt::printfln("ins::sty_zp, ${:X}", address)!;

        case ins::sty_zpx =>
            let address: u8 = fetch_byte();
            address += cpu.x;
            mem[address: u16] = cpu.y;
            cycles -= 4;
            fmt::printfln("ins::sty_zpx, ${:X}", address)!;

        case ins::sty_abs =>
            let address: u16 = fetch_word();
            mem[address] = cpu.y;
            cycles -= 4;
            fmt::printfln("ins::sty_abs, ${:X}", address)!;

            // ---------------
            // Jumps and Calls
            // ---------------
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
            cycles -= 1;    // it takes one cycle to fetch the opcode(1 byte)
            // break;
        };
    };
    return cyclesRequested - cycles;
};

export fn main() void = {
    assert(false, "Emulator entrypoint unimplemented!");
    // fmt::println("6502 Emulator has started lol")!;
    // cpu_reset();

    // // start - inline program
    // // Set reset vector to point to program start
    // mem[0xFFFC] = 0x43;
    // mem[0xFFFD] = 0xFE;

    // mem[0xFE43] = ins::jsr;
    // mem[0xFE44] = 0x52;
    // mem[0xFE45] = 0x42;
    // mem[0xFE46] = ins::lda_im;
    // mem[0xFE47] = 0x96;

    // mem[0x4252] = ins::lda_im;
    // mem[0x4253] = 0x69;
    // mem[0x4254] = ins::rts;
    // // end - inline program

    // cpu_execute(16);
    // fmt::printfln("CPU Register AC: ${:X}", cpu.ac)!;
};
