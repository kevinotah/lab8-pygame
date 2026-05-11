.intel_syntax noprefix

.section .rodata
fmt_frame:      .asciz "frame=%d alive=%d s0=(%.2f, %.2f) size=%d\n"
fmt_done:       .asciz "done: frames=%d alive=%d\n"

.equ SCREEN_WIDTH, 800
.equ SCREEN_HEIGHT, 600
.equ MAX_SPEED_I, 120
.equ DANGER_DISTANCE_I, 80
.equ MIN_SIZE, 4
.equ MAX_SIZE, 25
.equ MAX_GROWTH_SIZE, 50
.equ NUM_BIG, 5
.equ NUM_MED, 10
.equ NUM_SMALL, 30
.equ NUM_SQUARES, 45
.equ FRAMES, 600
.equ DT_MS, 16

.equ SQ_SIZE, 0
.equ SQ_X, 4
.equ SQ_Y, 8
.equ SQ_ANGLE, 12
.equ SQ_SPEED, 16
.equ SQ_LIFESPAN, 20
.equ SQ_AGE, 24
.equ SQ_ALIVE, 28
.equ SQ_BYTES, 32

.section .data
onef:           .float 1.0
zerof:          .float 0.0
dtf:            .float 0.016
pi2:            .float 6.283185307
dangerf:        .float 80.0
forcef:         .float 120.0
maxspeedf:      .float 120.0
minsizef:       .float 4.0
denomsizef:     .float 21.0
inv_rand_max:   .float 0.0000000004656613

.section .bss
.lcomm squares, SQ_BYTES * NUM_SQUARES

.section .text
.extern rand
.extern srand
.extern time
.extern printf
.extern sqrtf
.extern cosf
.extern sinf
.extern usleep

.globl main

# int rand_range(int lo, int hi)
rand_range:
    push rbp
    mov rbp, rsp
    call rand
    mov ecx, esi
    sub ecx, edi
    add ecx, 1
    cdq
    idiv ecx
    mov eax, edx
    add eax, edi
    pop rbp
    ret

# float rand_float_0_1()
rand_float_0_1:
    push rbp
    mov rbp, rsp
    call rand
    cvtsi2ss xmm0, eax
    mulss xmm0, DWORD PTR inv_rand_max[rip]
    pop rbp
    ret

# void init_square(index, size)
# rdi=index, esi=size
init_square:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov eax, SQ_BYTES
    imul eax, edi
    lea r8, squares[rip]
    add r8, rax

    mov DWORD PTR [r8 + SQ_SIZE], esi

    mov edi, 0
    mov eax, SCREEN_WIDTH
    sub eax, DWORD PTR [r8 + SQ_SIZE]
    mov esi, eax
    call rand_range
    cvtsi2ss xmm0, eax
    movss DWORD PTR [r8 + SQ_X], xmm0

    mov edi, 0
    mov eax, SCREEN_HEIGHT
    sub eax, DWORD PTR [r8 + SQ_SIZE]
    mov esi, eax
    call rand_range
    cvtsi2ss xmm0, eax
    movss DWORD PTR [r8 + SQ_Y], xmm0

    call rand_float_0_1
    mulss xmm0, DWORD PTR pi2[rip]
    movss DWORD PTR [r8 + SQ_ANGLE], xmm0

    mov eax, DWORD PTR [r8 + SQ_SIZE]
    sub eax, MIN_SIZE
    cvtsi2ss xmm0, eax
    divss xmm0, DWORD PTR denomsizef[rip]
    movss xmm1, DWORD PTR onef[rip]
    subss xmm1, xmm0
    mulss xmm1, DWORD PTR maxspeedf[rip]
    movss DWORD PTR [r8 + SQ_SPEED], xmm1

    mov edi, 30
    mov esi, 180
    call rand_range
    mov DWORD PTR [r8 + SQ_LIFESPAN], eax

    movss xmm0, DWORD PTR zerof[rip]
    movss DWORD PTR [r8 + SQ_AGE], xmm0
    mov DWORD PTR [r8 + SQ_ALIVE], 1

    leave
    ret

# int check_collision(a_ptr, b_ptr)
# rdi=a, rsi=b
check_collision:
    push rbp
    mov rbp, rsp

    movss xmm0, DWORD PTR [rdi + SQ_X]
    movss xmm1, DWORD PTR [rsi + SQ_X]
    mov eax, DWORD PTR [rsi + SQ_SIZE]
    cvtsi2ss xmm2, eax
    addss xmm1, xmm2
    ucomiss xmm0, xmm1
    jae .no

    movss xmm0, DWORD PTR [rdi + SQ_X]
    mov eax, DWORD PTR [rdi + SQ_SIZE]
    cvtsi2ss xmm2, eax
    addss xmm0, xmm2
    movss xmm1, DWORD PTR [rsi + SQ_X]
    ucomiss xmm0, xmm1
    jbe .no

    movss xmm0, DWORD PTR [rdi + SQ_Y]
    movss xmm1, DWORD PTR [rsi + SQ_Y]
    mov eax, DWORD PTR [rsi + SQ_SIZE]
    cvtsi2ss xmm2, eax
    addss xmm1, xmm2
    ucomiss xmm0, xmm1
    jae .no

    movss xmm0, DWORD PTR [rdi + SQ_Y]
    mov eax, DWORD PTR [rdi + SQ_SIZE]
    cvtsi2ss xmm2, eax
    addss xmm0, xmm2
    movss xmm1, DWORD PTR [rsi + SQ_Y]
    ucomiss xmm0, xmm1
    jbe .no

    mov eax, 1
    pop rbp
    ret

.no:
    xor eax, eax
    pop rbp
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    xor edi, edi
    call time
    mov edi, eax
    call srand

    xor ebx, ebx
.init_big:
    cmp ebx, NUM_BIG
    jge .init_med
    mov edi, ebx
    mov esi, 25
    call init_square
    inc ebx
    jmp .init_big

.init_med:
    cmp ebx, NUM_BIG + NUM_MED
    jge .init_small
    mov edi, ebx
    mov esi, 10
    call init_square
    inc ebx
    jmp .init_med

.init_small:
    cmp ebx, NUM_SQUARES
    jge .sim_start
    mov edi, ebx
    mov esi, 4
    call init_square
    inc ebx
    jmp .init_small

.sim_start:
    xor r12d, r12d

.frame_loop:
    cmp r12d, FRAMES
    jge .done

    xor r13d, r13d
.update_i:
    cmp r13d, NUM_SQUARES
    jge .age_pass

    mov eax, SQ_BYTES
    imul eax, r13d
    lea r14, squares[rip]
    add r14, rax

    cmp DWORD PTR [r14 + SQ_ALIVE], 1
    jne .next_i

    movss xmm0, DWORD PTR [r14 + SQ_ANGLE]
    call cosf
    mulss xmm0, DWORD PTR [r14 + SQ_SPEED]
    movss DWORD PTR [rbp-4], xmm0

    movss xmm0, DWORD PTR [r14 + SQ_ANGLE]
    call sinf
    mulss xmm0, DWORD PTR [r14 + SQ_SPEED]
    movss DWORD PTR [rbp-8], xmm0

    movss xmm6, DWORD PTR zerof[rip]
    movss DWORD PTR [rbp-12], xmm6
    movss DWORD PTR [rbp-16], xmm6
    movss DWORD PTR [rbp-20], xmm6
    movss DWORD PTR [rbp-24], xmm6

    xor r15d, r15d
.neighbors:
    cmp r15d, NUM_SQUARES
    jge .apply_forces
    cmp r15d, r13d
    je .n_next

    mov eax, SQ_BYTES
    imul eax, r15d
    lea rbx, squares[rip]
    add rbx, rax
    cmp DWORD PTR [rbx + SQ_ALIVE], 1
    jne .n_next

    movss xmm0, DWORD PTR [r14 + SQ_X]
    subss xmm0, DWORD PTR [rbx + SQ_X]
    movss DWORD PTR [rbp-28], xmm0

    movss xmm1, DWORD PTR [r14 + SQ_Y]
    subss xmm1, DWORD PTR [rbx + SQ_Y]
    movss DWORD PTR [rbp-32], xmm1

    movss xmm2, DWORD PTR [rbp-28]
    mulss xmm2, xmm2
    movss xmm3, DWORD PTR [rbp-32]
    mulss xmm3, xmm3
    addss xmm2, xmm3
    movss xmm0, xmm2
    call sqrtf
    movss DWORD PTR [rbp-36], xmm0

    ucomiss xmm0, DWORD PTR zerof[rip]
    jbe .n_next
    ucomiss xmm0, DWORD PTR dangerf[rip]
    jae .n_next

    mov eax, DWORD PTR [rbx + SQ_SIZE]
    cmp eax, DWORD PTR [r14 + SQ_SIZE]
    jle .maybe_chase

    movss xmm1, DWORD PTR onef[rip]
    movss xmm2, DWORD PTR [rbp-36]
    divss xmm2, DWORD PTR dangerf[rip]
    subss xmm1, xmm2

    movss xmm3, DWORD PTR [rbp-28]
    divss xmm3, DWORD PTR [rbp-36]
    mulss xmm3, xmm1
    addss xmm3, DWORD PTR [rbp-12]
    movss DWORD PTR [rbp-12], xmm3

    movss xmm4, DWORD PTR [rbp-32]
    divss xmm4, DWORD PTR [rbp-36]
    mulss xmm4, xmm1
    addss xmm4, DWORD PTR [rbp-16]
    movss DWORD PTR [rbp-16], xmm4
    jmp .n_next

.maybe_chase:
    mov eax, DWORD PTR [rbx + SQ_SIZE]
    cmp eax, DWORD PTR [r14 + SQ_SIZE]
    jge .n_next

    movss xmm1, DWORD PTR onef[rip]
    movss xmm2, DWORD PTR [rbp-36]
    divss xmm2, DWORD PTR dangerf[rip]
    subss xmm1, xmm2

    movss xmm3, DWORD PTR [rbp-28]
    divss xmm3, DWORD PTR [rbp-36]
    mulss xmm3, xmm1
    addss xmm3, DWORD PTR [rbp-20]
    movss DWORD PTR [rbp-20], xmm3

    movss xmm4, DWORD PTR [rbp-32]
    divss xmm4, DWORD PTR [rbp-36]
    mulss xmm4, xmm1
    addss xmm4, DWORD PTR [rbp-24]
    movss DWORD PTR [rbp-24], xmm4

.n_next:
    inc r15d
    jmp .neighbors

.apply_forces:
    movss xmm0, DWORD PTR [rbp-12]
    mulss xmm0, DWORD PTR forcef[rip]
    addss xmm0, DWORD PTR [rbp-4]
    movss DWORD PTR [rbp-4], xmm0

    movss xmm1, DWORD PTR [rbp-16]
    mulss xmm1, DWORD PTR forcef[rip]
    addss xmm1, DWORD PTR [rbp-8]
    movss DWORD PTR [rbp-8], xmm1

    movss xmm2, DWORD PTR [rbp-20]
    mulss xmm2, DWORD PTR forcef[rip]
    movss xmm0, DWORD PTR [rbp-4]
    subss xmm0, xmm2
    movss DWORD PTR [rbp-4], xmm0

    movss xmm3, DWORD PTR [rbp-24]
    mulss xmm3, DWORD PTR forcef[rip]
    movss xmm1, DWORD PTR [rbp-8]
    subss xmm1, xmm3
    movss DWORD PTR [rbp-8], xmm1

    movss xmm0, DWORD PTR [rbp-4]
    mulss xmm0, DWORD PTR dtf[rip]
    addss xmm0, DWORD PTR [r14 + SQ_X]
    movss DWORD PTR [r14 + SQ_X], xmm0

    movss xmm1, DWORD PTR [rbp-8]
    mulss xmm1, DWORD PTR dtf[rip]
    addss xmm1, DWORD PTR [r14 + SQ_Y]
    movss DWORD PTR [r14 + SQ_Y], xmm1

    ucomiss xmm0, DWORD PTR zerof[rip]
    jae .x_hi
    mov eax, SCREEN_WIDTH
    sub eax, DWORD PTR [r14 + SQ_SIZE]
    cvtsi2ss xmm0, eax
    movss DWORD PTR [r14 + SQ_X], xmm0
    jmp .y_wrap

.x_hi:
    mov eax, SCREEN_WIDTH
    sub eax, DWORD PTR [r14 + SQ_SIZE]
    cvtsi2ss xmm2, eax
    ucomiss xmm0, xmm2
    jbe .y_wrap
    movss xmm0, DWORD PTR zerof[rip]
    movss DWORD PTR [r14 + SQ_X], xmm0

.y_wrap:
    movss xmm1, DWORD PTR [r14 + SQ_Y]
    ucomiss xmm1, DWORD PTR zerof[rip]
    jae .y_hi
    mov eax, SCREEN_HEIGHT
    sub eax, DWORD PTR [r14 + SQ_SIZE]
    cvtsi2ss xmm1, eax
    movss DWORD PTR [r14 + SQ_Y], xmm1
    jmp .collide

.y_hi:
    mov eax, SCREEN_HEIGHT
    sub eax, DWORD PTR [r14 + SQ_SIZE]
    cvtsi2ss xmm2, eax
    ucomiss xmm1, xmm2
    jbe .collide
    movss xmm1, DWORD PTR zerof[rip]
    movss DWORD PTR [r14 + SQ_Y], xmm1

.collide:
    xor r15d, r15d
.collide_loop:
    cmp r15d, NUM_SQUARES
    jge .next_i
    cmp r15d, r13d
    je .c_next

    mov eax, SQ_BYTES
    imul eax, r15d
    lea rbx, squares[rip]
    add rbx, rax
    cmp DWORD PTR [rbx + SQ_ALIVE], 1
    jne .c_next

    mov rdi, r14
    mov rsi, rbx
    call check_collision
    test eax, eax
    jz .c_next

    mov eax, DWORD PTR [r14 + SQ_SIZE]
    cmp eax, DWORD PTR [rbx + SQ_SIZE]
    jle .c_next
    cmp eax, MAX_GROWTH_SIZE
    jge .c_next

    mov DWORD PTR [rbx + SQ_ALIVE], 0
    mov DWORD PTR [rbx + SQ_LIFESPAN], 0

    mov eax, DWORD PTR [rbx + SQ_SIZE]
    add DWORD PTR [r14 + SQ_SIZE], eax
    mov eax, DWORD PTR [r14 + SQ_SIZE]
    cmp eax, MAX_GROWTH_SIZE
    jle .c_next
    mov DWORD PTR [r14 + SQ_SIZE], MAX_GROWTH_SIZE

.c_next:
    inc r15d
    jmp .collide_loop

.next_i:
    inc r13d
    jmp .update_i

.age_pass:
    xor r13d, r13d
    xor r11d, r11d
.age_loop:
    cmp r13d, NUM_SQUARES
    jge .print_maybe
    mov eax, SQ_BYTES
    imul eax, r13d
    lea r14, squares[rip]
    add r14, rax

    cmp DWORD PTR [r14 + SQ_ALIVE], 1
    jne .respawn_dead

    movss xmm0, DWORD PTR [r14 + SQ_AGE]
    addss xmm0, DWORD PTR dtf[rip]
    movss DWORD PTR [r14 + SQ_AGE], xmm0
    cvtsi2ss xmm1, DWORD PTR [r14 + SQ_LIFESPAN]
    ucomiss xmm0, xmm1
    jb .count_alive

.respawn_dead:
    mov eax, DWORD PTR [r14 + SQ_SIZE]
    mov edi, r13d
    mov esi, eax
    call init_square

.count_alive:
    inc r11d
    inc r13d
    jmp .age_loop

.print_maybe:
    mov eax, r12d
    mov ecx, 30
    cdq
    idiv ecx
    test edx, edx
    jne .sleep_continue

    lea rdi, fmt_frame[rip]
    mov esi, r12d                # frame (int)
    mov edx, r11d                # alive (int)
    lea rax, squares[rip]
    movss xmm0, DWORD PTR [rax + SQ_X]
    cvtss2sd xmm0, xmm0          # s0.x as double in xmm0
    movss xmm1, DWORD PTR [rax + SQ_Y]
    cvtss2sd xmm1, xmm1          # s0.y as double in xmm1
    mov ecx, DWORD PTR [rax + SQ_SIZE]
    xor eax, eax
    call printf

.sleep_continue:
    mov edi, DT_MS * 1000
    call usleep
    inc r12d
    jmp .frame_loop

.done:
    xor r11d, r11d
    xor r13d, r13d
.count_alive_done:
    cmp r13d, NUM_SQUARES
    jge .print_done
    mov eax, SQ_BYTES
    imul eax, r13d
    lea r14, squares[rip]
    add r14, rax
    cmp DWORD PTR [r14 + SQ_ALIVE], 1
    jne .done_next
    inc r11d
.done_next:
    inc r13d
    jmp .count_alive_done

.print_done:
    lea rdi, fmt_done[rip]
    mov esi, FRAMES
    mov edx, r11d
    xor eax, eax
    call printf

    xor eax, eax
    leave
    ret