; ============================================================================
; 第10课：字符串操作 - 高效处理文本数据
; ============================================================================
;
; 第10课：字符串操作
; MOVSB/MOVSD/STOSB/SCASB/CMPSB + REP前缀——高效数据处理
;
; ============================================================================
; 一、字符串操作指令概述
; ============================================================================
;
; x86提供了一组专门的字符串操作指令：
;
; 指令    作用              等价C代码
; ----    ----              ---------
; MOVSB   移动字节          *dst++ = *src++
; MOVSW   移动字(2字节)     *(short*)dst++ = *(short*)src++
; MOVSD   移动双字(4字节)   *(int*)dst++ = *(int*)src++
; CMPSB   比较字节          cmp(*src++, *dst++)
; CMPSW   比较字            cmp(*(short*)src++, *(short*)dst++)
; CMPSD   比较双字          cmp(*(int*)src++, *(int*)dst++)
; SCASB   扫描字节          cmp(*dst++, al)
; SCASD   扫描双字          cmp(*(int*)dst++, eax)
; STOSB   存储字节          *dst++ = al
; STOSD   存储双字          *dst++ = eax
; LODSB   加载字节          al = *src++
; LODSD   加载双字          eax = *src++
;
; 这些指令都自动使用特定寄存器：
;   ESI = 源地址（Source Index）
;   EDI = 目标地址（Destination Index）
;   ECX = 计数器（与REP前缀配合）
;   AL/AX/EAX = 数据（取决于操作大小）
;   DF = 方向标志（0=正向递增，1=反向递减）
;
; 生活类比：
;   ESI = 源仓库的货架号（从哪里取）
;   EDI = 目标仓库的货架号（放到哪里）
;   ECX = 要搬多少箱（计数）
;   DF  = 搬运方向（从前往后还是从后往前）

section .data
    src_str db 'Hello, World!', 0
    dst_str db 14 dup(0)            ; 目标缓冲区
    pattern dd 0x41414141           ; 'AAAA' 的十六进制
    buffer  dd 100 dup(0)           ; 100个双字的缓冲区
    str1    db 'abcdef', 0
    str2    db 'abcxyz', 0

section .text
    extern _ExitProcess@4
    global _start

_start:
    ; ==================================================================
    ; 方向标志 DF
    ; ==================================================================
    ; DF=0：ESI/EDI 自动递增（从低地址到高地址）
    ; DF=1：ESI/EDI 自动递减（从高地址到低地址）

    cld                         ; Clear Direction Flag（DF=0，正向）
    ; std                     ; Set Direction Flag（DF=1，反向）
    ; 大多数情况下使用CLD（正向）

    ; ==================================================================
    ; MOVSB/MOVSD - 复制数据
    ; ==================================================================
    ; 复制一个字节/双字：从 [ESI] 到 [EDI]，然后 ESI/EDI 自动调整

    ; 单字节复制
    lea     esi, [src_str]      ; ESI -> 源字符串
    lea     edi, [dst_str]      ; EDI -> 目标缓冲区
    cld                         ; 正向复制

    movsb                       ; 复制1字节：[EDI] = [ESI]
                                ; ESI++, EDI++
    ; 现在 dst_str[0] = 'H'

    ; 双字复制
    lea     esi, [src_str]
    lea     edi, [dst_str]
    movsd                       ; 复制4字节：[EDI..EDI+3] = [ESI..ESI+3]
    ; dst_str = "Hell"（前4个字符）

    ; ==================================================================
    ; REP 前缀 - 重复执行
    ; ==================================================================
    ; REP 前缀让字符串指令重复执行 ECX 次
    ; 每次执行后 ECX--，直到 ECX=0
    ;
    ; 等价于：
    ; while (ECX != 0) {
    ;     执行字符串指令;
    ;     ECX--;
    ; }

    ; 用 REP MOVSB 复制整个字符串
    lea     esi, [src_str]      ; 源地址
    lea     edi, [dst_str]      ; 目标地址
    mov     ecx, 14             ; 要复制的字节数（包括 '\0'）
    cld                         ; 正向
    rep     movsb               ; 重复复制 ECX 次
    ; dst_str = "Hello, World!\0"

    ; 用 REP MOVSD 快速复制大块数据（比MOVSB快4倍）
    lea     esi, [buffer]
    lea     edi, [dst_str]
    mov     ecx, 3              ; 复制3个双字（12字节）
    rep     movsd               ; 快速复制

    ; ==================================================================
    ; STOSB/STOSD - 填充数据
    ; ==================================================================
    ; 把 AL/EAX 的值存到 [EDI]，然后 EDI 自动调整
    ; 常用于初始化缓冲区（memset）

    ; 用零填充缓冲区
    lea     edi, [buffer]
    mov     ecx, 100            ; 100个双字
    xor     eax, eax            ; EAX = 0
    cld
    rep     stosd               ; 重复存储 ECX 次
    ; buffer 全部填充为0

    ; 用特定值填充
    lea     edi, [buffer]
    mov     ecx, 50             ; 50个双字
    mov     eax, 0xCCCCCCCC     ; 填充值
    rep     stosd               ; 填充

    ; ==================================================================
    ; LODSB/LODSD - 加载数据
    ; ==================================================================
    ; 从 [ESI] 加载数据到 AL/EAX，然后 ESI 自动调整

    lea     esi, [src_str]
    cld
    lodsb                       ; AL = [ESI] = 'H'，ESI++
    lodsb                       ; AL = [ESI] = 'e'，ESI++
    ; ... 依此类推

    ; ==================================================================
    ; SCASB/SCASD - 扫描/搜索
    ; ==================================================================
    ; 比较 AL/EAX 和 [EDI]，设置标志位，然后 EDI 自动调整
    ; 常用于搜索字符串中的字符

    ; REPNESCASB = 搜索字符，找到为止
    lea     edi, [src_str]      ; 要搜索的字符串
    mov     al, 'W'             ; 要搜索的字符
    mov     ecx, 14             ; 最大搜索长度
    cld
    repne   scasb               ; 重复扫描，直到找到或ECX=0
    ; 如果找到：ZF=1，EDI指向找到位置的下一个字符
    ; 如果没找到：ZF=0，ECX=0
    ; EDI - 1 就是找到的位置

    ; 计算字符串长度（用SCASB找'\0'）
    lea     edi, [src_str]
    xor     al, al              ; AL = 0（搜索 '\0'）
    mov     ecx, -1             ; 最大长度（非常大）
    cld
    repne   scasb               ; 搜索 '\0'
    ; 长度 = -ECX - 2（或 ~ECX - 1）
    not     ecx                 ; ECX = ~ECX
    dec     ecx                 ; ECX = 长度（不含 '\0'）

    ; ==================================================================
    ; CMPSB/CMPSD - 比较数据
    ; ==================================================================
    ; 比较 [ESI] 和 [EDI]，设置标志位，然后 ESI/EDI 自动调整

    ; REPCMPSB = 逐字节比较，直到不同或ECX=0
    lea     esi, [str1]
    lea     edi, [str2]
    mov     ecx, 6              ; 比较6个字节
    cld
    repe    cmpsb               ; 重复比较，直到不同或ECX=0
    ; 如果完全相等：ECX=0, ZF=1
    ; 如果不同：ZF=0，ESI/EDI指向不同位置的下一个

    ; ==================================================================
    ; REP 前缀变体
    ; ==================================================================
    ;
    ; REP      - 重复直到 ECX=0（无条件重复）
    ; REPE/REPZ   - 重复直到 ECX=0 或 ZF=0（相等时继续）
    ; REPNE/REPNZ - 重复直到 ECX=0 或 ZF=1（不等时继续）
    ;
    ; 用途：
    ;   REP + MOVSB  = 复制内存块
    ;   REP + STOSB  = 填充内存块
    ;   REPE + CMPSB = 比较内存块（相等时继续）
    ;   REPNE + SCASB = 搜索字符（找到就停）

    ; ==================================================================
    ; 综合示例：字符串复制函数
    ; ==================================================================

    ; strcpy(dst, src) - 复制字符串
    push    dword dst_str       ; 目标
    push    dword src_str       ; 源
    call    my_strcpy
    add     esp, 8

    ; 综合示例：字符串长度函数
    push    dword src_str
    call    my_strlen
    add     esp, 4
    ; EAX = 字符串长度

    ; 退出程序
    push    0
    call    _ExitProcess@4

; ============================================================================
; 自定义字符串函数
; ============================================================================

; char* strcpy(char* dst, char* src)
my_strcpy:
    push    ebp
    mov     ebp, esp
    push    esi
    push    edi

    mov     edi, [ebp + 8]      ; dst
    mov     esi, [ebp + 12]     ; src
    xor     ecx, ecx            ; 计数器

.copy_loop:
    lodsb                       ; AL = [ESI++]
    stosb                       ; [EDI++] = AL
    test    al, al              ; 复制的是 '\0'?
    jnz     .copy_loop          ; 不是，继续

    mov     eax, [ebp + 8]      ; 返回 dst
    pop     edi
    pop     esi
    pop     ebp
    ret

; int strlen(char* str)
my_strlen:
    push    ebp
    mov     ebp, esp
    push    edi

    mov     edi, [ebp + 8]      ; str
    xor     al, al              ; 搜索 '\0'
    mov     ecx, -1             ; 最大长度
    cld
    repne   scasb               ; 搜索
    mov     eax, -2
    sub     eax, ecx            ; 长度 = -2 - ECX

    pop     edi
    pop     ebp
    ret

; ============================================================================
; 练习题
; ============================================================================
;
; 练习1（代码题）：
;   用字符串指令实现 memset(buffer, 0, 100)。
;
; 练习2（代码题）：
;   用字符串指令实现 strcmp(str1, str2)，返回0表示相等。
;
; 练习3（概念题）：
;   REP、REPE、REPNE 三个前缀有什么区别？分别在什么情况下使用？
;
; 练习4（代码题）：
;   用字符串指令实现 memcpy(dst, src, size)，支持任意大小。
;
; 练习5（思考题）：
;   为什么用 REP MOVSD 比 REP MOVSB 复制内存更快？
;
; ============================================================================
; 参考答案
; ============================================================================
;
; 答案1：
;   mov edi, buffer
;   mov ecx, 100
;   xor al, al
;   cld
;   rep stosb
;
; 答案2：
;   my_strcmp:
;       push ebp
;       mov ebp, esp
;       push esi
;       push edi
;       mov esi, [ebp+8]
;       mov edi, [ebp+12]
;       xor ecx, ecx
;   .loop:
;       lodsb
;       scasb
;       jne .not_equal
;       test al, al
;       jz .equal
;       jmp .loop
;   .not_equal:
;       mov eax, 1
;       jmp .done
;   .equal:
;       xor eax, eax
;   .done:
;       pop edi
;       pop esi
;       pop ebp
;       ret
;
; 答案3：
;   REP：无条件重复，用于MOVSB/STOSB等
;   REPE/REPZ：相等时重复，用于CMPSB（比较）
;   REPNE/REPNZ：不等时重复，用于SCASB（搜索）
;
; 答案4：
;   需要先计算需要多少个双字和剩余字节
;   my_memcpy:
;       push ebp
;       mov ebp, esp
;       push esi
;       push edi
;       push ecx
;       mov edi, [ebp+8]
;       mov esi, [ebp+12]
;       mov ecx, [ebp+16]
;       mov eax, ecx
;       shr ecx, 2          ; 除以4，得到双字数
;       cld
;       rep movsd           ; 复制双字
;       mov ecx, eax
;       and ecx, 3          ; 剩余字节数
;       rep movsb           ; 复制剩余字节
;       pop ecx
;       pop edi
;       pop esi
;       pop ebp
;       ret
;
; 答案5：
;   MOVSD每次复制4字节，MOVSB每次复制1字节。
;   复制同样的数据，MOVSD只需要1/4的循环次数。
;   每次循环都有开销（ECX--、判断、跳转），减少循环次数就减少了开销。
;   这就是为什么优化的memcpy总是先用MOVSD处理大部分数据，再用MOVSB处理剩余字节。
;
; ============================================================================
; 教授的话
; ============================================================================
;
; 【核心收获】
;
;   1. ESI=源地址，EDI=目标地址，ECX=计数器，DF=方向标志
;   2. REP前缀让指令重复ECX次（REP MOVSB = 批量复制）
;   3. MOVSB/MOVSD 复制，STOSB/STOSD 填充，SCASB 搜索，CMPSB 比较
;   4. REPE(相等继续)用于比较，REPNE(不等继续)用于搜索
;   5. MOVSD 比 MOVSB 快4倍（每次处理4字节 vs 1字节）
;   6. cld 清方向标志(正向)，std 设方向标志(反向)
;
; 【常见陷阱】
;
;   1. 忘记设置方向标志 cld，ESI/EDI 会反向递减
;   2. ECX 设错导致复制过多或过少（注意是否包含 '\0'）
;   3. REPNE SCASB 后 ECX 的剩余值需要取反再减1才是长度
;   4. ESI/EDI 必须指向有效内存地址，否则段错误
;
; 【下节课预告】
;
;   第11课将学习数组与结构体：一维/二维数组访问、[base+index*scale]寻址、
;   结构体字段偏移定义、内存对齐、选择排序实战。
;
; 保持好奇心，我们下节课见！
;                                    —— 教授
; ============================================================================

; =============================================
; 恭喜完成
; =============================================
; 恭喜你完成了第 10 课：字符串操作！
; 下节课我们将学习数组与结构体。
