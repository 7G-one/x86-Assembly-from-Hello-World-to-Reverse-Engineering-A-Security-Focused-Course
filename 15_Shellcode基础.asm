; ============================================================================
; 第15课：Shellcode基础 - 安全研究的起点
; ============================================================================
;
; 第15课：Shellcode基础
; 位置无关代码、避免坏字符、PEB获取API地址、XOR编码
;
; ============================================================================
; 一、什么是Shellcode？
; ============================================================================
;
; Shellcode是一段可以注入到程序中执行的机器码。
; 名字来源于它最初的目标：获取一个shell（命令行）。
;
; 生活类比：
;   想象你要给一个机器人下达指令，但你只能用机器语言（二进制）。
;   你精心编写了一段二进制指令（shellcode），
;   然后想办法让机器人执行你的指令（而不是它本来的任务）。
;
; Shellcode的特点：
;   1. 纯机器码，没有操作系统支持
;   2. 位置无关代码（PIC），可以在任何地址执行
;   3. 不能包含NULL字节（0x00），因为它是字符串结束符
;   4. 通常很小（几十到几百字节）
;
; Shellcode的典型用途：
;   - CTF比赛中的Pwn题目
;   - 漏洞利用（Exploit）
;   - 安全研究和渗透测试
;
; ============================================================================
; 二、编写第一个Shellcode：ExitShellcode
; ============================================================================
;
; 最简单的shellcode：调用ExitProcess(0)退出程序
;
; Windows API调用：
;   push 0
;   call ExitProcess
;
; 需要解决的问题：
;   1. 如何找到ExitProcess的地址？
;   2. 如何避免NULL字节？
;   3. 如何让代码位置无关？

section .text
    global _start

_start:
    ; ==================================================================
    ; 方法1：直接地址（不稳定，仅用于学习）
    ; ==================================================================
    ; 问题：ExitProcess的地址每次运行都可能变化（ASLR）
    ;
    ; push 0
    ; mov eax, 0x7C81CB12    ; ExitProcess的地址（硬编码，不可靠）
    ; call eax

    ; ==================================================================
    ; 方法2：通过PEB获取kernel32基址（经典方法）
    ; ==================================================================
    ; PEB（Process Environment Block）是Windows进程信息结构
    ; FS:[0x30] 指向 PEB
    ; PEB + 0x0C 指向 PEB_LDR_DATA
    ; PEB_LDR_DATA + 0x1C 指向 InInitializationOrderModuleList
    ; 第二个条目就是 kernel32.dll
    ;
    ; 生活类比：
    ;   你要找一家店的地址，你可以：
    ;   1. 直接记地址（不稳定，店可能搬家）
    ;   2. 查电话簿（通过已知的信息找到地址）

    ; 获取kernel32基址（简化版，实际shellcode中更复杂）
    xor     ecx, ecx            ; ECX = 0
    mov     eax, [fs:ecx + 0x30] ; EAX = PEB地址
    mov     eax, [eax + 0x0C]   ; EAX = PEB->Ldr
    mov     esi, [eax + 0x1C]   ; ESI = InInitializationOrderModuleList
    lodsd                       ; EAX = 第一个条目（ntdll）
    mov     ebx, [eax + 0x08]   ; EBX = ntdll基址
    lodsd                       ; EAX = 第二个条目
    mov     ebx, [eax + 0x08]   ; EBX = kernel32基址

    ; ==================================================================
    ; 方法3：哈希查找函数（高级Shellcode常用）
    ; ==================================================================
    ; 遍历导出表，用哈希值匹配函数名
    ; 这样不需要硬编码地址，也不需要字符串

    ; 函数名哈希计算示例（ROR13哈希）：
    ; hash = 0
    ; for each char in name:
    ;     hash = ROR(hash, 13) + char
    ;
    ; ExitProcess 的哈希值 = 0x04E94818（示例）

; ============================================================================
; 三、避免坏字符（Bad Characters）
; ============================================================================
;
; 坏字符是会导致shellcode被截断或修改的字节：
;   0x00 (NULL)    - 字符串结束符
;   0x0A (LF)      - 换行符（gets等函数会停止）
;   0x0D (CR)      - 回车符
;   0xFF           - 某些情况下有问题
;
; 避免坏字符的技巧：
;   1. 使用等价指令
;   2. 用算术运算生成需要的值
;   3. 编码（XOR、ADD等）

section .text
_start_badchar:
    ; 避免 NULL 字节的技巧：

    ; 原始：mov eax, 0  （包含 0x00）
    ; 替换：xor eax, eax （不含 0x00）

    ; 原始：push 0 （包含 0x00）
    ; 替换：
    xor     eax, eax
    push    eax                 ; push 0（不含NULL字节）

    ; 原始：mov eax, 0x00000001
    ; 替换：
    xor     eax, eax
    inc     eax                 ; EAX = 1

    ; 原始：mov eax, 0x01010101
    ; 替换：
    xor     eax, eax
    mov     al, 1
    imul    eax, eax, 0x01010101 ; EAX = 0x01010101

    ; 用 SUB 代替 MOV
    ; 原始：mov eax, 0x41414141
    ; 替换：
    mov     eax, 0x42424242     ; 先放一个没有坏字符的值
    sub     eax, 0x01010101     ; 0x42424242 - 0x01010101 = 0x41414141

; ============================================================================
; 四、Shellcode编码
; ============================================================================
;
; 有时候shellcode必须经过编码才能注入。
; 常见编码方式：
;   1. XOR编码
;   2. 字节ADD/SUB编码
;   3. 多态编码（每次运行都不同）
;
; XOR编码原理：
;   编码：encoded_byte = original_byte XOR key
;   解码：original_byte = encoded_byte XOR key
;   在shellcode前面加一段解码器，运行时先解码再执行

section .text
    ; XOR解码器示例（概念）
    ; 假设shellcode被XOR 0x55编码过

    ; jmp short get_encoded    ; 跳转到获取编码数据
    ; decode:
    ;     pop esi               ; ESI = 编码数据的地址
    ;     mov ecx, 20           ; 数据长度
    ;     xor eax, eax          ; 清零
    ; .decode_loop:
    ;     xor byte [esi], 0x55  ; 解码一个字节
    ;     inc esi               ; 下一个字节
    ;     dec ecx               ; 计数器减1
    ;     jnz .decode_loop      ; 继续
    ;     jmp short encoded_data; 跳转到解码后的shellcode
    ; get_encoded:
    ;     call decode           ; 把encoded_data的地址压栈
    ; encoded_data:
    ;     ; 编码后的shellcode在这里（用db定义）

; ============================================================================
; 五、完整的Windows MessageBox Shellcode
; ============================================================================
;
; 目标：弹出一个消息框
; 需要的API：MessageBoxA, ExitProcess
;
; 简化版（使用固定地址，实际中需要用PEB方法）

section .data
    ; 注意：实际shellcode中不能有.data段，所有数据都在代码中
    ; 这里只是方便演示

section .text
    ; MessageBoxA Shellcode 框架（概念）
    ;
    ; 1. 找到 user32.dll 基址
    ; 2. 找到 MessageBoxA 函数地址
    ; 3. 调用 MessageBoxA(NULL, "Hello", "Title", MB_OK)
    ; 4. 调用 ExitProcess(0)
    ;
    ; 伪代码：
    ; push 0                  ; MB_OK
    ; push "Title"            ; 标题
    ; push "Hello"            ; 内容
    ; push 0                  ; hWnd = NULL
    ; call MessageBoxA
    ;
    ; push 0                  ; 退出码
    ; call ExitProcess

; ============================================================================
; 六、Shellcode测试方法
; ============================================================================
;
; 测试shellcode的方法：
;
; 方法1：C程序加载测试
;   unsigned char shellcode[] = "\xfc\x48\x83...";
;   int main() {
;       ((void(*)())shellcode)();
;       return 0;
;   }
;
; 方法2：使用专门的工具
;   - nasm汇编后提取.text段
;   - 使用shellcode加载器
;
; 方法3：在线工具
;   - shell-storm.org/shellcode
;   - exploit-db.com/shellcode

; ============================================================================
; 练习题
; ============================================================================
;
; 练习1（代码题）：
;   写一个最简单的shellcode：调用ExitProcess(0)。
;   确保不包含NULL字节。
;
; 练习2（概念题）：
;   为什么shellcode不能包含NULL字节？列出至少3种避免NULL字节的方法。
;
; 练习3（代码题）：
;   写一个XOR解码器，解码密钥为0xAA。
;
; 练习4（概念题）：
;   什么是位置无关代码（PIC）？为什么shellcode必须是PIC？
;
; 练习5（思考题）：
;   如何绕过NX（不可执行栈）保护？（提示：ROP技术）
;
; ============================================================================
; 参考答案
; ============================================================================
;
; 答案1：
;   xor eax, eax            ; EAX = 0
;   push eax                ; 退出码 = 0
;   mov eax, <ExitProcess地址> ; 需要动态获取
;   call eax
;
; 答案2：
;   NULL字节(0x00)是C字符串结束符，会被strcpy等函数截断。
;   避免方法：
;   1. xor reg, reg 代替 mov reg, 0
;   2. inc/dec 生成小数值
;   3. 用算术运算代替mov大数值
;   4. 用XOR/ADD编码
;
; 答案3：
;   decode:
;       pop esi
;       mov ecx, 20
;   .loop:
;       xor byte [esi], 0xAA
;       inc esi
;       dec ecx
;       jnz .loop
;       jmp short encoded
;   get_data:
;       call decode
;   encoded:
;       ; 编码后的数据
;
; 答案4：
;   PIC = 代码不依赖于绝对地址，可以在任何位置正确执行。
;   shellcode必须是PIC因为：
;   1. 注入位置不确定
;   2. ASLR使地址随机化
;   3. 不同环境地址不同
;
; 答案5：
;   NX保护使栈/堆不可执行。
;   绕过方法（ROP）：
;   1. 在可执行段（如.text）找到有用的代码片段（gadgets）
;   2. 用ROP链组合这些片段
;   3. 通过控制栈上的返回地址，依次跳转到各个gadget
;   4. 最终执行VirtualProtect或mprotect修改内存权限
;   或者使用Return-to-libc技术直接调用system("/bin/sh")
;
; ============================================================================
; 教授的话
; ============================================================================
;
; 【核心收获】
;
;   1. Shellcode = 可注入执行的纯机器码，目标：获取shell或执行任意操作
;   2. 位置无关代码(PIC)：不依赖绝对地址，任何位置都能执行
;   3. 坏字符：0x00(NULL截断)、0x0A(换行)、0x0D(回车)必须避免
;   4. 获取API地址：PEB -> LDR -> InInitializationOrderModuleList -> kernel32基址
;   5. XOR编码：encoded = original ^ key，解码器在shellcode前运行
;
; 【常见陷阱】
;
;   1. 硬编码API地址不可靠（ASLR每次运行地址不同）
;   2. mov eax, 0 包含NULL字节，用 xor eax, eax 替代
;   3. push 0 也包含NULL，用 xor eax,eax + push eax 替代
;   4. shellcode中不能有 .data 段，所有数据必须嵌入代码中
;
; 【下节课预告】
;
;   第16课将学习栈溢出原理：缓冲区溢出、覆盖返回地址、
;   NX/ASLR/Canary防护机制、ret2libc和ROP绕过技术。
; ============================================================================

; =============================================
; 恭喜完成
; =============================================
; 恭喜你完成了第 15 课：Shellcode基础！
; 下节课我们将学习栈溢出原理。
