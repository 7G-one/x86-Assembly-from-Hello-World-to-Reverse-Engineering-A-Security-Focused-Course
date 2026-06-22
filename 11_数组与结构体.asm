; ============================================================================
; 第11课：数组与结构体 - 复杂数据结构
; ============================================================================
;
; 第11课：数组与结构体
; 一维/二维数组访问、结构体字段偏移、内存对齐
;
; ============================================================================
; 一、数组操作
; ============================================================================
;
; 数组 = 连续存放的相同类型数据
;
; 生活类比：
;   数组就像一排储物柜，每个柜子大小相同，编号连续。
;   要找第N个柜子：起始位置 + N * 每个柜子的大小
;
; 访问公式：
;   数组元素地址 = 基地址 + 索引 * 元素大小
;
; x86支持的寻址模式：
;   [base + index * scale]
;   scale = 1, 2, 4, 8（对应 byte, word, dword, qword）

section .data
    ; 各种类型的数组
    byte_arr    db  10, 20, 30, 40, 50           ; 字节数组
    word_arr    dw  100, 200, 300, 400, 500      ; 字数组
    dword_arr   dd  1000, 2000, 3000, 4000, 5000 ; 双字数组
    float_arr   dd  1.0, 2.5, 3.7, 4.2, 5.9     ; 浮点数组

    ; 二维数组（行优先存储）
    ; matrix[3][4] = {
    ;     {1, 2, 3, 4},
    ;     {5, 6, 7, 8},
    ;     {9, 10, 11, 12}
    ; }
    matrix      dd  1, 2, 3, 4
                dd  5, 6, 7, 8
                dd  9, 10, 11, 12
    MATRIX_COLS equ 4

section .bss
    result_arr  resd 10

section .text
    extern _ExitProcess@4
    global _start

_start:
    ; ==================================================================
    ; 一维数组访问
    ; ==================================================================

    ; 访问 byte_arr[2] = 30
    mov     al, [byte_arr + 2]      ; 每个元素1字节，偏移 = 2*1 = 2

    ; 访问 word_arr[3] = 400
    mov     ax, [word_arr + 3*2]    ; 每个元素2字节，偏移 = 3*2 = 6

    ; 访问 dword_arr[4] = 5000
    mov     eax, [dword_arr + 4*4]  ; 每个元素4字节，偏移 = 4*4 = 16

    ; 用寄存器作为索引
    mov     ecx, 2                  ; 索引 = 2
    mov     eax, [dword_arr + ecx*4] ; dword_arr[2] = 3000

    ; ==================================================================
    ; 数组遍历
    ; ==================================================================

    ; 计算 dword_arr 的所有元素之和
    xor     eax, eax                ; sum = 0
    xor     ecx, ecx                ; i = 0
.sum_loop:
    add     eax, [dword_arr + ecx*4] ; sum += dword_arr[i]
    inc     ecx                      ; i++
    cmp     ecx, 5                   ; i < 5?
    jl      .sum_loop
    ; EAX = 1000+2000+3000+4000+5000 = 15000

    ; ==================================================================
    ; 数组求最大值
    ; ==================================================================

    mov     eax, [dword_arr]        ; max = arr[0]
    mov     ecx, 1                  ; i = 1
.max_loop:
    cmp     ecx, 5
    jge     .max_done
    mov     ebx, [dword_arr + ecx*4]
    cmp     ebx, eax
    jle     .not_bigger
    mov     eax, ebx                ; max = arr[i]
.not_bigger:
    inc     ecx
    jmp     .max_loop
.max_done:
    ; EAX = 最大值

    ; ==================================================================
    ; 二维数组访问
    ; ==================================================================
    ; matrix[row][col] = matrix + (row * COLS + col) * 4
    ;
    ; 生活类比：
    ;   二维数组就像电影院的座位：
    ;   row = 第几排，col = 第几号
    ;   实际位置 = 第(row * 每排座位数 + col)个座位

    ; 访问 matrix[1][2] = 7
    mov     eax, 1                  ; row = 1
    imul    eax, MATRIX_COLS        ; row * COLS = 1 * 4 = 4
    add     eax, 2                  ; + col = 4 + 2 = 6
    mov     eax, [matrix + eax*4]   ; matrix[1][2] = 7

    ; 用 LEA 计算索引
    mov     ecx, 1                  ; row
    mov     edx, 2                  ; col
    lea     eax, [ecx*4 + edx]      ; eax = row*COLS + col = 6
    mov     eax, [matrix + eax*4]   ; matrix[1][2] = 7

    ; ==================================================================
    ; 数组排序（选择排序）
    ; ==================================================================
    ; 对 dword_arr 进行升序排序

    mov     ecx, 0                  ; i = 0
.sel_outer:
    cmp     ecx, 4                  ; i < n-1?
    jge     .sel_done
    mov     edx, ecx                ; min_idx = i
    mov     ebx, ecx
    inc     ebx                     ; j = i + 1
.sel_inner:
    cmp     ebx, 5                  ; j < n?
    jge     .sel_swap
    mov     eax, [dword_arr + ebx*4]
    cmp     eax, [dword_arr + edx*4]
    jge     .sel_not_min
    mov     edx, ebx                ; min_idx = j
.sel_not_min:
    inc     ebx
    jmp     .sel_inner
.sel_swap:
    ; 交换 arr[i] 和 arr[min_idx]
    mov     eax, [dword_arr + ecx*4]
    mov     ebx, [dword_arr + edx*4]
    mov     [dword_arr + ecx*4], ebx
    mov     [dword_arr + edx*4], eax
    inc     ecx
    jmp     .sel_outer
.sel_done:

    ; ==================================================================
    ; 数组反转
    ; ==================================================================

    lea     esi, [dword_arr]
    xor     ecx, ecx                ; left = 0
    mov     edx, 4                  ; right = n-1
.rev_loop:
    cmp     ecx, edx
    jge     .rev_done
    mov     eax, [esi + ecx*4]
    mov     ebx, [esi + edx*4]
    mov     [esi + ecx*4], ebx
    mov     [esi + edx*4], eax
    inc     ecx
    dec     edx
    jmp     .rev_loop
.rev_done:

    ; 退出程序
    push    0
    call    _ExitProcess@4

; ============================================================================
; 二、结构体
; ============================================================================
;
; 结构体 = 不同类型数据的组合
;
; 生活类比：
;   结构体就像一张表格：
;   每行是一个字段，每个字段有自己的大小和含义。
;
; C语言：
;   struct Person {
;       char name[32];    // 偏移 0,  大小 32
;       int age;          // 偏移 32, 大小 4
;       float height;     // 偏移 36, 大小 4
;       int id;           // 偏移 40, 大小 4
;   };  // 总大小 44
;
; NASM中用 equ 定义偏移量：

; 结构体字段偏移定义
PERSON_NAME     equ 0               ; name[32] 偏移0
PERSON_AGE      equ 32              ; int 偏移32
PERSON_HEIGHT   equ 36              ; float 偏移36
PERSON_ID       equ 40              ; int 偏移40
PERSON_SIZE     equ 44              ; 结构体总大小

section .data
    ; 定义一个Person结构体实例
    person1:
        db 'Zhang San', 0           ; name（需要32字节，不足补0）
        times 22 db 0               ; 填充到32字节
        dd 25                       ; age = 25
        dd 175                      ; height = 175（用整数代替浮点简化）
        dd 1001                     ; id = 1001

    ; 数组中的结构体
    persons:
        ; Person 0
        db 'Alice', 0
        times 27 db 0
        dd 20, 165, 1
        ; Person 1
        db 'Bob', 0
        times 29 db 0
        dd 22, 180, 2
        ; Person 2
        db 'Charlie', 0
        times 24 db 0
        dd 25, 175, 3

section .text
    ; ==================================================================
    ; 访问结构体字段
    ; ==================================================================

    ; 访问 person1.age
    mov     eax, [person1 + PERSON_AGE]     ; EAX = 25

    ; 访问 person1.id
    mov     ebx, [person1 + PERSON_ID]      ; EBX = 1001

    ; 修改 person1.age
    mov     dword [person1 + PERSON_AGE], 26 ; age = 26

    ; ==================================================================
    ; 访问结构体数组
    ; ==================================================================
    ; persons[i].field = persons + i * PERSON_SIZE + field_offset

    ; 访问 persons[1].age
    mov     eax, 1                          ; 索引 = 1
    imul    eax, PERSON_SIZE                ; 偏移 = 1 * 44 = 44
    mov     ebx, [persons + eax + PERSON_AGE] ; persons[1].age = 22

    ; 遍历结构体数组
    xor     ecx, ecx                        ; i = 0
.person_loop:
    cmp     ecx, 3                          ; i < 3?
    jge     .person_done
    mov     eax, ecx
    imul    eax, PERSON_SIZE                ; i * sizeof(Person)
    ; 可以在这里访问 persons[i] 的各个字段
    ; mov ebx, [persons + eax + PERSON_AGE]
    inc     ecx
    jmp     .person_loop
.person_done:

    ; ==================================================================
    ; 嵌套结构体
    ; ==================================================================
    ; struct Inner { int x; int y; };           // 大小 8
    ; struct Outer { Inner pos; int z; };       // 大小 12
    ;
    ; 访问 outer.pos.x = [outer + 0]
    ; 访问 outer.pos.y = [outer + 4]
    ; 访问 outer.z     = [outer + 8]

    ; ==================================================================
    ; 内存对齐
    ; ==================================================================
    ;
    ; 现代CPU访问对齐的数据更快。
    ; 编译器通常会在字段之间插入填充字节使每个字段都对齐。
    ;
    ; 未对齐的结构体：
    ;   struct Bad {
    ;       char a;     // 偏移 0, 大小 1
    ;       int b;      // 偏移 1? 不对！应该是 4
    ;       char c;     // 偏移 5? 不对！应该是 8
    ;   };
    ;
    ; 对齐后的结构体：
    ;   struct Good {
    ;       char a;     // 偏移 0,  大小 1
    ;       // 3字节填充
    ;       int b;      // 偏移 4,  大小 4
    ;       char c;     // 偏移 8,  大小 1
    ;       // 3字节填充（使结构体大小是4的倍数）
    ;   };  // 总大小 12
    ;
    ; 在NASM中需要手动处理对齐：
    ;   用 times N db 0 填充

    ; 退出（这部分代码在之前已经退出了，这里只是概念演示）

; ============================================================================
; 练习题
; ============================================================================
;
; 练习1（代码题）：
;   定义一个包含5个DWORD的数组，计算其平均值。
;
; 练习2（代码题）：
;   定义一个结构体 Student { name[20], score, grade }，
;   创建3个学生，找出分数最高的学生。
;
; 练习3（代码题）：
;   实现一个函数，接收数组和长度，返回数组中所有正数的和。
;
; 练习4（概念题）：
;   为什么访问 dword_arr[i] 时要乘以4？如果访问 word_arr[i] 呢？
;
; 练习5（思考题）：
;   内存对齐有什么好处？为什么不把所有数据都紧密排列？
;
; ============================================================================
; 参考答案
; ============================================================================
;
; 答案1：
;   section .data
;   arr dd 10, 20, 30, 40, 50
;   section .text
;   xor eax, eax
;   xor ecx, ecx
;   .loop:
;       add eax, [arr + ecx*4]
;       inc ecx
;       cmp ecx, 5
;       jl .loop
;   cdq
;   mov ecx, 5
;   idiv ecx
;   ; EAX = 平均值
;
; 答案2：
;   定义结构体偏移：
;   STUDENT_NAME equ 0
;   STUDENT_SCORE equ 20
;   STUDENT_GRADE equ 24
;   STUDENT_SIZE equ 28
;   找最高分：遍历数组，比较STUDENT_SCORE字段
;
; 答案3：
;   positive_sum:
;       push ebp
;       mov ebp, esp
;       mov esi, [ebp+8]      ; 数组指针
;       mov ecx, [ebp+12]     ; 长度
;       xor eax, eax          ; sum = 0
;   .loop:
;       test ecx, ecx
;       jz .done
;       mov ebx, [esi]
;       test ebx, ebx
;       jle .skip
;       add eax, ebx
;   .skip:
;       add esi, 4
;       dec ecx
;       jmp .loop
;   .done:
;       pop ebp
;       ret
;
; 答案4：
;   因为每个DWORD占4字节。数组元素地址 = 基地址 + 索引 * 元素大小。
;   dword_arr[i] = dword_arr + i * 4
;   word_arr[i] = word_arr + i * 2
;   byte_arr[i] = byte_arr + i * 1
;
; 答案5：
;   CPU以固定大小的块（通常4字节）从内存读取数据。
;   如果数据跨越两个块，CPU需要两次内存访问。
;   对齐的数据保证在单个块内，只需一次访问。
;   虽然浪费了一些空间，但大大提高了访问速度。
;
; ============================================================================
; 教授的话
; ============================================================================
;
; 【核心收获】
;
;   1. 数组元素地址 = 基地址 + 索引 * 元素大小
;   2. x86寻址：[base + index * scale]，scale=1/2/4/8
;   3. 二维数组行优先存储：matrix[row][col] = base + (row*COLS+col)*4
;   4. 结构体用 equ 定义字段偏移（如 PERSON_AGE equ 32）
;   5. 结构体数组：persons[i].field = persons + i * PERSON_SIZE + field_offset
;   6. 内存对齐：4字节数据放在4的倍数地址上，访问更快
;
; 【常见陷阱】
;
;   1. 访问 word_arr[i] 偏移是 i*2，dword_arr[i] 偏移是 i*4，别搞混
;   2. 结构体大小要考虑对齐填充（如 char+int 实际占8字节不是5字节）
;   3. scale 只能是 1/2/4/8，不能用 3/5 等其他值
;   4. 二维数组越界：row*COLS+col 超出数组范围会读到垃圾数据
;
; 【下节课预告】
;
;   第12课将学习浮点运算：FPU寄存器栈(80位)、FLD/FST/FADD/FMUL、
;   FCOM浮点比较、整数浮点互转、SSE/AVX SIMD简介。
; ============================================================================

; =============================================
; 恭喜完成
; =============================================
; 恭喜你完成了第 11 课：数组与结构体！
; 下节课我们将学习浮点运算。
