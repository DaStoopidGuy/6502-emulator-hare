/*
Making an emulator?
6502 Processor

Links:
----------------------------
https://youtu.be/qJgsuQoy9bc
https://github.com/davepoo/6502Emulator
https://sta.c64.org/cbm64mem.html

-> 6502
http://6502.org/users/obelisk/6502/registers.html
----------------------------
*/

#include <assert.h>
#include <stdio.h>

// #define Byte unsigned char
// #define Word unsigned short

typedef unsigned char   Byte;
typedef unsigned short  Word;

#define MAX_MEM 1024 * 64
typedef struct
{
    // static constexpr unsigned int MAX_MEM = 1024 * 64;
    Byte Data[MAX_MEM];
} Mem;

void Mem_Initialize(Mem *mem)
{
    for (unsigned int i = 0; i < MAX_MEM; i++)
    {
        mem->Data[i] = 0;
    }
}

/* write 2 bytes */
void Mem_WriteWord(Mem *mem, unsigned int *Cycles, Word Value, Byte Address)
{
    mem->Data[Address]      = Value & 0xFF;
    mem->Data[Address + 1]  = (Value >> 8);
    *Cycles -= 2;
}

typedef struct
{
    Word PC;      // Program Counter - 16 bits
    Byte SP;      // Stack Pointer - 8 bits
    Byte A, X, Y; // the only 3 Registers :P

    // Processor Status Flags
    Byte C : 1; // Carry Flag
    Byte Z : 1; // Zero Flag
    Byte I : 1; // Interrupt Disable
    Byte D : 1; // Decimal Mode
    Byte B : 1; // Break Command
    Byte O : 1; // Overflow Flag
    Byte N : 1; // Negative Flag
} CPU;

void CPU_Reset(CPU *cpu, Mem *mem)
{
    cpu->PC = 0xFFFC; // execution address of cold reset
    cpu->SP = 0x0100; // initialize stack ptr

    cpu->C = 0;
    cpu->Z = 0;
    cpu->I = 0;
    cpu->D = 0;
    cpu->B = 0;
    cpu->O = 0;
    cpu->N = 0;

    cpu->A = cpu->X = cpu->Y = 0;

    Mem_Initialize(mem);
}

Byte CPU_FetchByte(CPU *cpu, Mem *mem, unsigned int *Cycles)
{
    assert(cpu->PC < MAX_MEM);
    Byte Data = mem->Data[cpu->PC];
    cpu->PC++;
    (*Cycles)--;
    return Data;
}

Word CPU_FetchWord(CPU *cpu, Mem *mem, unsigned int *Cycles)
{
    // 6502 is little endian
    assert(cpu->PC < MAX_MEM);
    Word Data = mem->Data[cpu->PC];
    cpu->PC++;

    Data |= (mem->Data[cpu->PC] << 8);
    cpu->PC++;

    *Cycles -= 2;

    /*
    if you wanted to handle endianness
    you would swap bytes here
    if ( PLATFORM_BIG_ENDIAN )
    {
        SwapBytesInWord(&Data);
    }
    */
    return Data;

}

Byte CPU_ReadByte(Byte Address, Mem *mem, unsigned int *Cycles)
{
    assert(Address < MAX_MEM);
    Byte Data = mem->Data[Address];
    (*Cycles)--;
    return Data;
}

// opcodes
enum
{
    INS_LDA_IM  = 0xA9,
    INS_LDA_ZP  = 0xA5,
    INS_LDA_ZPX = 0xB5, 
    INS_JSR     = 0x20,
};

void CPU_LDASetStatus(CPU *cpu)
{
    cpu->Z = (cpu->A == 0);             // Set if A == 0
    cpu->N = (cpu->A & 0b10000000) > 0; // Set if bit 7 of A is set
}

void CPU_Execute(CPU *cpu, Mem *mem, unsigned int Cycles)
{
    while (Cycles > 0)
    {
        Byte Ins = CPU_FetchByte(cpu, mem, &Cycles);
        switch (Ins)
        {
        case INS_LDA_IM:
        {
            Byte Value = CPU_FetchByte(cpu, mem, &Cycles);
            cpu->A = Value;
            CPU_LDASetStatus(cpu);
            printf("INS_LDA_IM, %X\n", Value);
            break;
        }
        case INS_LDA_ZP:
        {
            Byte ZeroPageAddr = CPU_FetchByte(cpu, mem, &Cycles);
            cpu->A = CPU_ReadByte(ZeroPageAddr, mem, &Cycles);
            CPU_LDASetStatus(cpu);
            printf("INS_LDA_ZP\n");
            break;
        }
        case INS_LDA_ZPX:
        {
            Byte ZeroPageAddr = CPU_FetchByte(cpu, mem, &Cycles);
            ZeroPageAddr += cpu->X;
            Cycles--;
            cpu->A = CPU_ReadByte(ZeroPageAddr, mem, &Cycles);
            CPU_LDASetStatus(cpu);
            printf("INS_LDA_ZPX\n");
            break;
        }
        case INS_JSR:
        {
            Word SubAddr = CPU_FetchWord(cpu, mem, &Cycles);
            Mem_WriteWord(mem, &Cycles, cpu->PC - 1, cpu->SP);
            cpu->SP += 1;
            cpu->PC = SubAddr;
            Cycles--;
            printf("INS_JSR, %X\n", SubAddr);
            break;
        }
        default:
        {
            printf("Instruction not handled: %X\n", Ins);
            break;
        }
        }
    }
}

int main()
{
    Mem mem;
    CPU cpu;
    CPU_Reset(&cpu, &mem);

    // start - inline program
    mem.Data[0xFFFC] = INS_JSR;
    mem.Data[0xFFFD] = 0x42;
    mem.Data[0xFFFE] = 0x42;
    mem.Data[0x4242] = INS_LDA_IM;
    mem.Data[0x4243] = 0x84;
    // end - inline program

    CPU_Execute(&cpu, &mem, 8);
    printf("CPU Register A: %X\n", cpu.A);
    return 0;
}
