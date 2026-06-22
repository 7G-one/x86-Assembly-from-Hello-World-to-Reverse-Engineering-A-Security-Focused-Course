; ============================================================================
; 第07课：循环结构 - 让程序重复劳动
; ============================================================================
;
; 第07课：循环结构
; LOOP指令、while/do-while模式、嵌套循环、break/continue
;
; ============================================================================
; 一、LOOP 指令 - 专用循环指令
; ============================================================================
;
; 语法：LOOP 标签
; 作用：ECX = ECX - 1，如果 ECX != 0 则跳转到标签
;
; 等价于：
;   dec ecx
;   jnz 标签
;
; 生活类比：
;   LOOP就像一个倒计时器：你设定要循环几次（放入ECX），
;   每循环一次计数器减1，到0就停止。

section .data
    numbers dd 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
    count   equ 10
    sum     dd 0
    buffer  db '0000000000', 0    ; 用于存放转换后的数字

section .text
    extern _ExitProcess@4
    global _start

_start:
    ; ==================================================================
    ; LOOP 基本用法
    ; ==================================================================

    ; 计算 1+2+3+...+10
    xor     eax, eax            ; sum = 0
    mov     ecx, 10             ; 循环10次
.loop_basic:
    add     eax, ecx            ; sum += ECX（从10加到1）
    loop    .loop_basic         ; ECX--, 如果ECX!=0则继续循环
    ; EAX = 10+9+8+...+1 = 55
    ; 注意：LOOP是从ECX往1倒着加的

    ; ==================================================================
    ; 手动实现循环（更灵活）
    ; ==================================================================
    ; LOOP 的缺点：只能用ECX，且只能在短跳转范围内
    ; 手动循环更常用、更灵活

    ; 计算数组求和
    xor     eax, eax            ; sum = 0
    xor     ecx, ecx            ; i = 0（索引）
.sum_loop:
    add     eax, [numbers + ecx*4]  ; sum += numbers[i]
    inc     ecx                     ; i++
    cmp     ecx, count              ; i < count?
    jl      .sum_loop               ; 如果是，继续循环
    mov     [sum], eax              ; 保存结果

    ; ==================================================================
    ; while 循环模式
    ; ==================================================================
    ; C: while (condition) { body }
    ; 汇编: 先检查条件，再执行循环体

    mov     eax, 100
.while_loop:
    test    eax, eax            ; eax == 0?
    jz      .while_end          ; 如果是0，结束循环
    shr     eax, 1              ; eax >>= 1（右移一位 = 除以2）
    jmp     .while_loop
.while_end:
    ; EAX最终 = 0（100不断除以2直到变成0）

    ; ==================================================================
    ; do-while 循环模式
    ; ==================================================================
    ; C: do { body } while (condition);
    ; 汇编: 先执行循环体，再检查条件（至少执行一次）

    mov     eax, 1
.do_while:
    add     eax, eax            ; eax *= 2
    cmp     eax, 1000           ; eax < 1000?
    jl      .do_while           ; 如果是，继续
    ; EAX = 1024（第一个 >= 1000 的2的幂）

    ; ==================================================================
    ; 嵌套循环
    ; ==================================================================
    ; 外层循环用 ECX，内层循环怎么办？
    ; 解决方案：内层循环计数保存在栈中或另一个寄存器

    ; 示例：打印乘法表的思路（简化版）
    ; for (i = 1; i <= 9; i++)
    ;   for (j = 1; j <= i; j++)
    ;       result = i * j;

    xor     eax, eax            ; 结果累加器
    mov     ecx, 1              ; i = 1（外层计数）
.outer_loop:
    push    ecx                 ; 保存外层计数器
    mov     edx, 1              ; j = 1（内层计数）
.inner_loop:
    ; 计算 i * j
    push    ecx                 ; 保存 i
    push    edx                 ; 保存 j
    imul    ecx, edx            ; ECX = i * j
    add     eax, ecx            ; 累加结果
    pop     edx                 ; 恢复 j
    pop     ecx                 ; 恢复 i
    inc     edx                 ; j++
    cmp     edx, ecx            ; j <= i?
    jle     .inner_loop
    pop     ecx                 ; 恢复外层计数器
    inc     ecx                 ; i++
    cmp     ecx, 10             ; i <= 9?
    jl      .outer_loop
    ; EAX = 所有 i*j 的和

    ; ==================================================================
    ; 循环控制：break 和 continue
    ; ==================================================================

    ; break: 直接跳出循环
    ; continue: 跳到循环的下一次迭代

    ; 示例：遍历数组，找到第一个大于50的数就停止
    xor     ecx, ecx            ; i = 0
.find_loop:
    cmp     ecx, count          ; i < count?
    jge     .find_end           ; 超出数组范围，结束
    mov     eax, [numbers + ecx*4]  ; eax = numbers[i]
    cmp     eax, 50             ; numbers[i] > 50?
    jg      .found_it           ; 找到了！跳出循环（break）
    inc     ecx                 ; i++
    jmp     .find_loop
.found_it:
    ; EAX = 第一个大于50的数，ECX = 它的索引
.find_end:

    ; 示例：遍历数组，跳过偶数，只处理奇数
    xor     ecx, ecx            ; i = 0
    xor     eax, eax            ; 奇数和 = 0
.skip_loop:
    cmp     ecx, count
    jge     .skip_end
    mov     ebx, [numbers + ecx*4]
    test    ebx, 1              ; 检查是否为偶数
    jz      .skip_even          ; 偶数就跳过（continue）
    add     eax, ebx            ; 奇数才累加
.skip_even:                     ; continue 跳到这里
    inc     ecx
    jmp     .skip_loop
.skip_end:

    ; ==================================================================
    ; 字符串遍历示例
    ; ==================================================================
    ; 遍历一个字符串，计算长度

section .data
    my_str  db 'Hello, Assembly!', 0

section .text
    lea     esi, [my_str]       ; ESI 指向字符串开头
    xor     ecx, ecx            ; 长度 = 0
.strlen_loop:
    mov     al, [esi + ecx]     ; 取当前字符
    test    al, al              ; 是否为 '\0'?
    jz      .strlen_end         ; 是，结束
    inc     ecx                 ; 长度++
    jmp     .strlen_loop
.strlen_end:
    ; ECX = 字符串长度（不含 '\0'）

    ; ==================================================================
    ; 数组求最大值
    ; ==================================================================

    lea     esi, [numbers]
    mov     eax, [esi]          ; max = numbers[0]
    mov     ecx, 1              ; i = 1
.max_loop:
    cmp     ecx, count
    jge     .max_end
    mov     ebx, [esi + ecx*4]  ; ebx = numbers[i]
    cmp     ebx, eax            ; numbers[i] > max?
    jle     .not_bigger
    mov     eax, ebx            ; max = numbers[i]
.not_bigger:
    inc     ecx
    jmp     .max_loop
.max_end:
    ; EAX = 数组中的最大值

    ; ==================================================================
    ; 冒泡排序（经典算法演示）
    ; ==================================================================
    ; 对数组进行升序排序

    mov     ecx, count          ; 外层循环次数
    dec     ecx                 ; n-1 次
.bubble_outer:
    push    ecx                 ; 保存外层计数
    xor     edx, edx            ; j = 0
.bubble_inner:
    mov     eax, [numbers + edx*4]      ; eax = arr[j]
    mov     ebx, [numbers + edx*4 + 4]  ; ebx = arr[j+1]
    cmp     eax, ebx            ; arr[j] > arr[j+1]?
    jle     .no_swap            ; 不需要交换
    ; 交换
    mov     [numbers + edx*4], ebx
    mov     [numbers + edx*4 + 4], eax
.no_swap:
    inc     edx                 ; j++
    cmp     edx, ecx            ; j < 内层循环次数?
    jl      .bubble_inner
    pop     ecx                 ; 恢复外层计数
    loop    .bubble_outer       ; 外层循环

    ; ==================================================================
    ; 延迟循环（空循环，用于延迟）
    ; ==================================================================

    mov     ecx, 1000000        ; 循环次数
.delay_loop:
    nop                         ; No Operation（空操作，什么都不做）
    loop    .delay_loop         ; 继续循环

    ; 退出程序
    push    0
    call    _ExitProcess@4

; ============================================================================
; 练习题
; ============================================================================
;
; 练习1（代码题）：
;   用 LOOP 指令计算 1*2*3*...*10（10的阶乘），结果放在 EAX 中。
;   注意：结果可能会超过32位！
;
; 练习2（代码题）：
;   写一段代码，遍历一个字节数组，统计其中值为0的元素个数。
;
; 练习3（代码题）：
;   实现一个简单的字符串反转函数：把 "Hello" 变成 "olleH"。
;   （提示：用两个指针，一个从头一个从尾，交换字符）
;
; 练习4（概念题）：
;   LOOP 指令和手动实现的 dec+jnz 循环有什么区别？什么情况下必须用手动循环？
;
; 练习5（挑战题）：
;   实现斐波那契数列的前20项计算，结果存入一个DWORD数组中。
;   F(0)=0, F(1)=1, F(n)=F(n-1)+F(n-2)
;
; ============================================================================
; 参考答案
; ============================================================================
;
; 答案1：
;   mov eax, 1              ; result = 1
;   mov ecx, 10             ; n = 10
;   .fact_loop:
;       imul eax, ecx       ; result *= n
;       loop .fact_loop     ; n--, continue if n!=0
;   ; EAX = 3628800 (10!)
;   ; 注意：32位只能存到12!，更大的需要64位
;
; 答案2：
;   lea esi, [byte_array]
;   xor ecx, ecx            ; i = 0
;   xor edx, edx            ; count = 0
;   .count_loop:
;       cmp ecx, array_len
;       jge .count_end
;       cmp byte [esi + ecx], 0
;       jne .not_zero
;       inc edx              ; 找到一个0
;   .not_zero:
;       inc ecx
;       jmp .count_loop
;   .count_end:
;   ; EDX = 零的个数
;
; 答案3：
;   lea esi, [my_string]
;   xor ecx, ecx            ; left = 0
;   ; 计算长度
;   .len_loop:
;       cmp byte [esi + ecx], 0
;       je .len_done
;       inc ecx
;       jmp .len_loop
;   .len_done:
;   dec ecx                  ; right = len - 1
;   xor edx, edx            ; left = 0
;   .rev_loop:
;       cmp edx, ecx
;       jge .rev_end
;       mov al, [esi + edx]
;       mov bl, [esi + ecx]
;       mov [esi + edx], bl
;       mov [esi + ecx], al
;       inc edx
;       dec ecx
;       jmp .rev_loop
;   .rev_end:
;
; 答案4：
;   LOOP 只能用 ECX 作为计数器，且跳转范围有限（短跳转）
;   如果 ECX 已经有其他用途，或者需要循环超过 2^32 次，
;   或者循环体很大（跳转距离超过128字节），就必须用手动循环
;
; 答案5：
;   section .data
;   fib_arr dd 20 dup(0)
;   section .text
;   mov dword [fib_arr], 0       ; F(0) = 0
;   mov dword [fib_arr + 4], 1   ; F(1) = 1
;   mov ecx, 2                   ; i = 2
;   .fib_loop:
;       mov eax, [fib_arr + ecx*4 - 4]  ; F(i-1)
;       add eax, [fib_arr + ecx*4 - 8]  ; + F(i-2)
;       mov [fib_arr + ecx*4], eax      ; F(i) = F(i-1) + F(i-2)
;       inc ecx
;       cmp ecx, 20
;       jl .fib_loop
;
; ============================================================================
; 教授的话
; ============================================================================
;
; 【核心收获】
;
;   1. LOOP 自动用 ECX 计数（dec ecx + jnz），但只能短跳转
;   2. 手动循环 cmp+jmp 更灵活更常用，不限于 ECX
;   3. while模式：先检查条件再执行；do-while模式：先执行再检查
;   4. 嵌套循环：外层计数器 push 保存，内层用其他寄存器
;   5. break = jmp 到循环外，continue = jmp 到循环末尾
;   6. 冒泡排序：双重循环 + 比较交换，经典算法入门
;
; 【常见陷阱】
;
;   1. LOOP 只能用 ECX，且跳转范围有限（短跳转128字节）
;   2. 嵌套循环忘记保存外层 ECX，内层会把它覆盖掉
;   3. 循环变量初始化放错位置（如放在循环体内每次被重置）
;   4. 数组越界：循环条件写成 <= 而非 < 导致多访问一个元素
;
; 【下节课预告】
;
;   第08课将学习栈与函数调用(上)：栈的工作原理、CALL/RET、
;   PUSHAD/POPAD、cdecl与stdcall调用约定。
; ============================================================================

; =============================================
; 恭喜完成
; =============================================
; 恭喜你完成了第 07 课：循环结构！
; 下节课我们将学习栈与函数调用（上）。
