// TODO: properly rewrite the tests to avoid foot choppage
fn test_start() void = {
    cpu_reset();
    mem[0xFFFC] = 0x43;
    mem[0xFFFD] = 0xFE;
};

@test fn executing_a_bad_instruction_doesnt_put_us_in_infinite_loop() void = {
    test_start();
    mem[0xFE43] = 0x00;
    mem[0xFE44] = 0x00;

    let cyclesUsed = cpu_execute(2);
    assert(cyclesUsed == 2);
};

// ----------------------
// LDA - Load Accumulator
// ----------------------
@test fn lda_im() void = {
    const value: u8 = 0x69;
    test_start();

    mem[0xFE43] = ins::lda_im;
    mem[0xFE44] = value;

    let cyclesUsed = cpu_execute(2);
    assert(cyclesUsed == 2);
    assert(cpu.ac == value);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_zp() void = {
    test_start();
    mem[0xFE43] = ins::lda_zp;
    mem[0xFE44] = 0x33;
    mem[0x0033] = 0x69;

    let cyclesUsed = cpu_execute(3);
    assert(cyclesUsed == 3);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_zpx() void = {
    test_start();
    cpu.x = 0x03;
    mem[0xFE43] = ins::lda_zpx;
    mem[0xFE44] = 0x30;
    mem[0x0033] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_abs() void = {
    test_start();
    mem[0xFE43] = ins::lda_abs;
    mem[0xFE44] = 0x69;
    mem[0xFE45] = 0x42;
    mem[0x4269] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_absx_page_not_crossed() void = {
    test_start();
    cpu.x = 0x03;
    mem[0xFE43] = ins::lda_absx;
    mem[0xFE44] = 0x00;
    mem[0xFE45] = 0x42;
    mem[0x4203] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_absx_page_crossed() void = {
    test_start();
    cpu.x = 0x01;
    mem[0xFE43] = ins::lda_absx;
    mem[0xFE44] = 0xff;
    mem[0xFE45] = 0x42;
    mem[0x4300] = 0x69; // page is crossed

    let cyclesused = cpu_execute(5);
    assert(cyclesused == 5);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_absy_page_not_crossed() void = {
    test_start();
    cpu.y = 0x03;
    mem[0xFE43] = ins::lda_absy;
    mem[0xFE44] = 0x00;
    mem[0xFE45] = 0x42;
    mem[0x4203] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_absy_page_crossed() void = {
    test_start();
    cpu.y = 0x01;
    mem[0xFE43] = ins::lda_absy;
    mem[0xFE44] = 0xff;
    mem[0xFE45] = 0x42;
    mem[0x4300] = 0x69; // page is crossed

    let cyclesUsed = cpu_execute(5);
    assert(cyclesUsed == 5);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_indx() void = {
    test_start();
    cpu.x = 0x23;
    mem[0xFE43] = ins::lda_indx;
    mem[0xFE44] = 0x32;
    mem[0x0055] = 0xEE;
    mem[0x0056] = 0xEA;
    mem[0xEAEE] = 0x69;

    let cyclesUsed = cpu_execute(6);
    assert(cyclesUsed == 6);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_indy_page_not_crossed() void = {
    test_start();
    cpu.y = 0x03;
    mem[0xFE43] = ins::lda_indy;
    mem[0xFE44] = 0x55;
    mem[0x0055] = 0x00;
    mem[0x0056] = 0xEA;
    mem[0xEA03] = 0x69;

    let cyclesUsed = cpu_execute(5);
    assert(cyclesUsed == 5);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn lda_indy_page_crossed() void = {
    test_start();
    cpu.y = 0x01;
    mem[0xFE43] = ins::lda_indy;
    mem[0xFE44] = 0x55; // 0x0055
    mem[0x0055] = 0xFF; // 0xEAFF + 0x0001 (Y reg)
    mem[0x0056] = 0xEA; // = 0xEB00
    mem[0xEB00] = 0x69; // fetch byte from this into ac

    let cyclesUsed = cpu_execute(6);
    assert(cyclesUsed == 6);
    assert(cpu.ac == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

// ---------------------
// LDX - Load X Register
// ---------------------
@test fn ldx_im() void = {
    test_start();
    mem[0xFE43] = ins::ldx_im;
    mem[0xFE44] = 0x69;

    let cyclesUsed = cpu_execute(2);
    assert(cyclesUsed == 2);
    assert(cpu.x == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldx_zp() void = {
    test_start();
    mem[0xFE43] = ins::ldx_zp;
    mem[0xFE44] = 0x32;
    mem[0x0032] = 0x69;

    let cyclesUsed = cpu_execute(3);
    assert(cpu.x == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldx_zpy() void = {
    test_start();
    cpu.y = 0x21;
    mem[0xFE43] = ins::ldx_zpy;
    mem[0xFE44] = 0x32;
    mem[0x0053] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cpu.x == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldx_abs() void = {
    test_start();
    mem[0xFE43] = ins::ldx_abs;
    mem[0xFE44] = 0xEE;
    mem[0xFE45] = 0xEA;
    mem[0xEAEE] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cpu.x == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldx_absy_page_not_crossed() void = {
    test_start();
    cpu.y = 0x33;
    mem[0xFE43] = ins::ldx_absy;
    mem[0xFE44] = 0x66;
    mem[0xFE45] = 0xEA;
    mem[0xEA99] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.x == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldx_absy_page_crossed() void = {
    test_start();
    cpu.y = 0x01;
    mem[0xFE43] = ins::ldx_absy;
    mem[0xFE44] = 0xFF;
    mem[0xFE45] = 0xEA;
    mem[0xEB00] = 0x69;

    let cyclesUsed = cpu_execute(5);
    assert(cyclesUsed == 5);
    assert(cpu.x == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

// ---------------------
// LDY - Load Y Register
// ---------------------
@test fn ldy_im() void = {
    test_start();
    mem[0xFE43] = ins::ldy_im;
    mem[0xFE44] = 0x69;

    let cyclesUsed = cpu_execute(2);
    assert(cyclesUsed == 2);
    assert(cpu.y == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldy_zp() void = {
    test_start();
    mem[0xFE43] = ins::ldy_zp;
    mem[0xFE44] = 0x82;
    mem[0x0082] = 0x69;

    let cyclesUsed = cpu_execute(3);
    assert(cyclesUsed == 3);
    assert(cpu.y == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldy_zpx() void = {
    test_start();
    cpu.x = 0x03;
    mem[0xFE43] = ins::ldy_zpx;
    mem[0xFE44] = 0x30;
    mem[0x0033] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.y == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldy_abs() void = {
    test_start();
    mem[0xFE43] = ins::ldy_abs;
    mem[0xFE44] = 0x69;
    mem[0xFE45] = 0x42;
    mem[0x4269] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.y == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldy_absx_page_not_crossed() void = {
    test_start();
    cpu.x = 0x03;
    mem[0xFE43] = ins::ldy_absx;
    mem[0xFE44] = 0x00;
    mem[0xFE45] = 0x42;
    mem[0x4203] = 0x69;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(cpu.y == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

@test fn ldy_absx_page_crossed() void = {
    test_start();
    cpu.x = 0x01;
    mem[0xFE43] = ins::ldy_absx;
    mem[0xFE44] = 0xFF;
    mem[0xFE45] = 0x42;
    mem[0x4300] = 0x69;

    let cyclesUsed = cpu_execute(5);
    assert(cyclesUsed == 5);
    assert(cpu.y == 0x69);
    assert(cpu.Z == false);
    assert(cpu.N == false);
};

// -----------------------
// STA - Store Accumulator
// -----------------------
@test fn sta_zp() void = {
    test_start();
    cpu.ac = 0x69;
    mem[0xFE43] = ins::sta_zp;
    mem[0xFE44] = 0x33;

    let cyclesUsed = cpu_execute(3);
    assert(cyclesUsed == 3);
    assert(mem[0x0033] == cpu.ac);
};

@test fn sta_zpx() void = {
    test_start();
    cpu.ac = 0x69;
    cpu.x = 0x03;
    mem[0xFE43] = ins::sta_zpx;
    mem[0xFE44] = 0x30;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(mem[0x0033] == cpu.ac);
};

@test fn sta_abs() void = {
    test_start();
    cpu.ac = 0x69;
    mem[0xFE43] = ins::sta_abs;
    mem[0xFE44] = 0x69;
    mem[0xFE45] = 0x42;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(mem[0x4269] == cpu.ac);
};

@test fn sta_absx() void = {
    test_start();
    cpu.ac = 0x69;
    cpu.x = 0x03;
    mem[0xFE43] = ins::sta_absx;
    mem[0xFE44] = 0x30;
    mem[0xFE45] = 0xEA;

    let cyclesUsed = cpu_execute(5);
    assert(cyclesUsed == 5);
    assert(mem[0xEA33] == cpu.ac);
};

@test fn sta_absy() void = {
    test_start();
    cpu.ac = 0x69;
    cpu.y = 0x03;
    mem[0xFE43] = ins::sta_absy;
    mem[0xFE44] = 0x30;
    mem[0xFE45] = 0xEA;

    let cyclesUsed = cpu_execute(5);
    assert(cyclesUsed == 5);
    assert(mem[0xEA33] == cpu.ac);
};

@test fn sta_indx() void = {
    test_start();
    cpu.ac = 0x69;
    cpu.x = 0x23;
    mem[0xFE43] = ins::sta_indx;
    mem[0xFE44] = 0x32;
    mem[0x0055] = 0xEE;
    mem[0x0056] = 0xEA;

    let cyclesUsed = cpu_execute(6);
    assert(cyclesUsed == 6);
    assert(mem[0xEAEE] == cpu.ac);
};

@test fn sta_indy() void = {
    test_start();
    cpu.ac = 0x69;
    cpu.y = 0x01;
    mem[0xFE43] = ins::sta_indy;
    mem[0xFE44] = 0x55;
    mem[0x0055] = 0xFF;
    mem[0x0056] = 0xEA;

    let cyclesUsed = cpu_execute(6);
    assert(cyclesUsed == 6);
    assert(mem[0xEB00] == cpu.ac);
};

// ----------------------
// STX - Store X Register
// ----------------------
@test fn stx_zp() void = {
    test_start();
    cpu.x = 0x69;
    mem[0xFE43] = ins::stx_zp;
    mem[0xFE44] = 0x33;

    let cyclesUsed = cpu_execute(3);
    assert(cyclesUsed == 3);
    assert(mem[0x0033] == cpu.x);
};

@test fn stx_zpy() void = {
    test_start();
    cpu.x = 0x69;
    cpu.y = 0x22;
    mem[0xFE43] = ins::stx_zpy;
    mem[0xFE44] = 0x33;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(mem[0x0055] == cpu.x);
};

@test fn stx_abs() void = {
    test_start();
    cpu.x = 0x69;
    mem[0xFE43] = ins::stx_abs;
    mem[0xFE44] = 0xEE;
    mem[0xFE45] = 0xEA;

    let cyclesUsed = cpu_execute(4);
    assert(cyclesUsed == 4);
    assert(mem[0xEAEE] == cpu.x);
};

// ---------------
// Jumps and Calls
// ---------------
@test fn jsr_and_rts() void = {
    test_start();

    mem[0xFE43] = ins::jsr;
    mem[0xFE44] = 0x00;
    mem[0xFE45] = 0x69;
    mem[0xFE46] = ins::lda_im;
    mem[0xFE47] = 0x69;

    mem[0x6900] = ins::ldx_im;
    mem[0x6901] = 0x42;
    mem[0x6902] = ins::rts;

    let cyclesUsed = cpu_execute(16);
    assert(cyclesUsed == 16);
    assert(cpu.x == 0x42);
    assert(cpu.ac == 0x69);
};
