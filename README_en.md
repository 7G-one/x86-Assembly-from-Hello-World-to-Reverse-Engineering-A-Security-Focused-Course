# x86 Assembly: From Hello World to Reverse Engineering

<h3 align="center"><a href="README.md">中文</a> | <a href="README_en.md">English</a></h3>

Assembly is the programming language closest to the CPU. You don't learn it to build business apps -- you learn it to truly understand what a computer does at the lowest level, and how security researchers use it to find vulnerabilities, write shellcode, and reverse-engineer software.

This course starts from "what is assembly" and takes you through 18 lessons to real IDA reverse engineering. Zero prerequisites required, but it gets increasingly thrilling as you go.

## What You'll Actually Learn

### Basics (00-06) -- Getting to Know Your CPU

| Lesson | File | What You'll Do | What You'll Pick Up Along the Way |
|--------|------|----------------|-----------------------------------|
| 00 | `00_零基础入门.asm` | Write your first assembly program | What assembly is, how a CPU works, how computers "see" the world |
| 01 | `01_寄存器详解.asm` | Use registers to store and retrieve data | General/pointer/segment/flags registers -- the CPU's "workbench" |
| 02 | `02_数据定义与内存.asm` | Define and manage data in memory | DB/DW/DD/DQ, byte order, memory layout |
| 03 | `03_数据传送指令.asm` | Move data between registers and memory | MOV/LEA/XCHG/PUSH/POP, MOVZX/MOVSX |
| 04 | `04_算术运算指令.asm` | Let the CPU do math for you | ADD/SUB/MUL/DIV, flags (overflow, carry) |
| 05 | `05_逻辑与位运算.asm` | Manipulate individual bits directly | AND/OR/XOR/NOT, shifts and rotates |
| 06 | `06_比较与跳转.asm` | Teach your program to make choices | CMP/TEST, conditional jumps, unconditional JMP |

### Intermediate (07-13) -- Understanding a Program's Skeleton

| Lesson | File | What You'll Do | What You'll Pick Up Along the Way |
|--------|------|----------------|-----------------------------------|
| 07 | `07_循环结构.asm` | Implement loops in assembly | LOOP instruction, manual loops, nested loops |
| 08 | `08_栈与函数调用上.asm` | Understand how function calls work under the hood | How the stack works, CALL/RET, calling conventions |
| 09 | `09_栈与函数调用下.asm` | Go deep on stack frames and parameter passing | Local variables, recursion, stack frame layout (core knowledge for security!) |
| 10 | `10_字符串操作.asm` | Process strings efficiently | MOVS/CMPS/SCAS/STOS/LODS, REP prefix |
| 11 | `11_数组与结构体.asm` | Manage complex data in assembly | Array access, struct definition, memory alignment |
| 12 | `12_浮点运算.asm` | Make the CPU handle decimals | FPU register stack, floating-point instructions, SIMD intro |
| 13 | `13_中断与系统调用.asm` | Talk to the operating system | Interrupt mechanism, INT instruction, Windows API calls |

### Hands-on (14-17) -- Where Security Research Begins

| Lesson | File | What You'll Do | What You'll Pick Up Along the Way |
|--------|------|----------------|-----------------------------------|
| 14 | `14_内联汇编与混合编程.asm` | Embed assembly inside C code | Calling convention matching, how C and assembly work together |
| 15 | `15_Shellcode基础.asm` | Write real shellcode | Shellcode encoding/decoding, avoiding bad characters, injection principles |
| 16 | `16_栈溢出原理.asm` | Understand the most classic exploit technique | Buffer overflow, control flow hijacking, defenses (DEP/ASLR/Stack Canary) |
| 17 | `17_逆向分析入门.asm` | Use IDA to understand someone else's program | Disassembly reading, reverse engineering mindset, hands-on analysis |

## Learning Path

Don't skip around -- shellcode and reverse engineering need everything that came before:

```
00 Getting Started → 01 Registers → 02 Data & Memory
    ↓
03 Data Movement → 04 Arithmetic → 05 Bitwise Ops → 06 Compare & Jump
    ↓
07 Loops → 08-09 Stack & Function Calls → 10 String Operations
    ↓
11 Arrays & Structs → 12 Floating Point → 13 Interrupts & Syscalls
    ↓
14 Inline Assembly → 15 Shellcode → 16 Stack Overflow → 17 Reverse Engineering
```

## What Makes This Course Different

### From Zero to Security Research, One Continuous Line

This isn't a "syntax only" assembly course. It starts from the most basic registers and goes all the way to writing shellcode, exploiting stack overflows, and reverse engineering with IDA. Complete the journey and you'll have the fundamentals of security research.

### Real-Life Analogies, Making the Abstract Concrete

- **Register** = a workbench -- only so much space to work with
- **Memory** = a warehouse -- lots of room but slower to access
- **Stack** = stacking plates -- last in, first out
- **CALL/RET** = making a phone call -- CALL dials, RET hangs up
- **Stack overflow** = too many plates stacked -- they spill over and smash nearby stuff
- **Shellcode** = a secret note of instructions slipped in where it shouldn't be

### Exercises and Answers in Every Lesson

Assembly is a hands-on skill. Reading without typing is the same as not learning. Every lesson has practice problems -- finish them to pass.

### Comments That Read Like a Teacher Standing Behind You

Every `.asm` file is packed with comments explaining what each instruction does, why it's written this way, and what happens if you change it.

## What You Need

| Tool | Purpose | Recommended |
|------|---------|-------------|
| Assembler | Turn `.asm` into `.obj` | [NASM](https://www.nasm.us/) |
| Linker | Turn `.obj` into `.exe` | GoLink or MSVC's link.exe |
| Debugger | Step through code, inspect registers and memory | x64dbg (recommended), OllyDbg, WinDbg |
| RE Tools | Disassemble and analyze statically | IDA Free / Ghidra |
| Platform | -- | Windows 32-bit |

## How to Build

```bash
# Assemble
nasm -f win32 00_零基础入门.asm -o 00.obj

# Link (GoLink)
golink /entry:_start 00.obj kernel32.dll user32.dll

# Or MSVC link
link /subsystem:console /entry:_start 00.obj kernel32.lib user32.lib
```

## Study Tips

1. **Follow the order**: Later material depends on earlier knowledge. Skip ahead and you'll be lost.
2. **Type every line of code**: Copy-paste won't teach you assembly.
3. **Use the debugger to step through**: Watch registers and memory change in real time -- this is the fastest way to learn.
4. **Do the exercises**: They're the only way to verify you actually understand.
5. **Practice, practice, practice**: Assembly is a craft. The more you write, the more natural it becomes.

## Debugger Recommendations

| Debugger | Platform | Notes |
|----------|----------|-------|
| x64dbg | Windows | Open source, 32/64-bit, beginner-friendly. Best starting point. |
| OllyDbg | Windows | Classic 32-bit debugger. Old but solid. |
| WinDbg | Windows | Microsoft's official tool. Powerful but steep learning curve. |
| GDB | Linux | Command line. Pair it with GEF or pwndbg plugins. |

## Recommended Resources

- [NASM Official Docs](https://www.nasm.us/doc/)
- [Intel Software Developer Manuals](https://software.intel.com/en-us/articles/intel-sdm)
- [x86 Instruction Reference](https://www.felixcloutier.com/x86/)
- [CTF Wiki - Pwn](https://ctf-wiki.org/pwn/linux/user-mode/stackoverflow/x86/stackoverflow-basic/)
- [Exploit Database](https://www.exploit-db.com/)

---

> Registers are the workbench, memory is the warehouse, the stack is a pile of plates -- assembly isn't magic, it's just speaking the CPU's native language. After these 18 lessons, you won't just read assembly -- you'll write shellcode, analyze stack overflows, and reverse-engineer programs with IDA. From Hello World to reverse engineering, you've made it.
