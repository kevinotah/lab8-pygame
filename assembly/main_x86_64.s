; ============================================================================
; Educational x86_64 System V (NASM-like) mapping of main.py (Python + pygame)
; ============================================================================
; Assumptions and limitations:
; 1) This is an illustrative translation, not a drop-in, fully linkable build.
;    Python object model, pygame internals, GC, and dynamic dispatch are modeled
;    as explicit runtime helper calls.
; 2) Floating-point math uses scalar SSE (xmm registers) for clarity.
; 3) Lists are represented as contiguous arrays of pointers + count/capacity.
; 4) Random/pygame/font helpers are declared as extern stubs to preserve logic.
; 5) Behavior is preserved at runtime-logic level:
;    - Square state
;    - update loop
;    - flee/chase vectors
;    - AABB collision check
;    - main event/render loop and respawn aging
; ============================================================================

default rel
bits 64

; -----------------------------
; External runtime/helper stubs
; -----------------------------
extern  rt_malloc                    ; rdi=size -> rax=ptr
extern  rt_free                      ; rdi=ptr
extern  rt_list_init                 ; rdi=list*
extern  rt_list_append               ; rdi=list*, rsi=item*
extern  rt_list_get                  ; rdi=list*, esi=index -> rax=item*
extern  rt_list_set                  ; rdi=list*, esi=index, rdx=item*
extern  rt_list_clear                ; rdi=list*
extern  rt_list_swap                 ; rdi=listA*, rsi=listB*
extern  rt_len                       ; rdi=list* -> eax=count

extern  rand_int_range               ; edi=min, esi=max -> eax (inclusive)
extern  rand_float_range             ; xmm0=min, xmm1=max -> xmm0
extern  cosf                         ; xmm0=angle -> xmm0
extern  sinf                         ; xmm0=angle -> xmm0
extern  sqrtf                        ; xmm0=val -> xmm0

extern  pygame_init
extern  pygame_quit
extern  pygame_display_set_mode      ; edi=w, esi=h -> rax=screen*
extern  pygame_display_set_caption   ; rdi=char*
extern  pygame_clock_new             ; -> rax=clock*
extern  pygame_clock_tick            ; rdi=clock*, esi=fps -> eax=ms
extern  pygame_clock_get_fps         ; rdi=clock* -> xmm0=float
extern  pygame_event_poll            ; rdi=event* -> eax=has_event (0/1)
extern  pygame_screen_fill_rgb       ; rdi=screen*, esi=r, edx=g, ecx=b
extern  pygame_draw_rect             ; rdi=screen*, esi=r, edx=g, ecx=b, r8d=x, r9d=y, [rsp+8]=w, [rsp+16]=h
extern  pygame_display_flip
extern  font_default_new             ; edi=size -> rax=font*
extern  font_render_text             ; rdi=font*, rsi=char*, edx=antialias, ecx=r, r8d=g, r9d=b -> rax=surface*
extern  screen_blit                  ; rdi=screen*, rsi=surface*, edx=x, ecx=y
extern  fmt_int_to_text              ; rdi=fmt*, esi=int -> rax=cstr*
extern  fmt_float3_to_text           ; rdi=fmt*, xmm0=float -> rax=cstr*

; -----------------------------
; Constants (from Python code)
; -----------------------------
section .rodata
SCREEN_WIDTH         dd 800
SCREEN_HEIGHT        dd 600
FPS_CONST            dd 60
MAX_SPEED            dd 120.0
DANGER_DISTANCE      dd 80.0
MIN_SIZE_CONST       dd 4
MAX_SIZE_CONST       dd 25
MAX_GROWTH_SIZE      dd 50
TWO_PI               dd 6.283185307
ZERO_F               dd 0.0
ONE_F                dd 1.0
SCALE_FORCE          dd 120.0
DIR_JITTER_SCALE     dd 0.8
DT_DIVISOR_MS        dd 1000.0
BLACK_R              dd 0
BLACK_G              dd 0
BLACK_B              dd 0
TXT_FMT_SQUARES      db "%d squares",0
TXT_FMT_FPS          db "FPS: %.3f",0
WINDOW_TITLE         db "Smooth Squares",0

; -----------------------------
; Data layout
; -----------------------------
; struct Square {
;   int   size
;   float x, y
;   int   color_r, color_g, color_b
;   float angle
;   float direction_timer
;   float direction_change_interval
;   float speed
;   int   lifespan
;   float age
; }
%define SQ_size                     0
%define SQ_x                        4
%define SQ_y                        8
%define SQ_color_r                  12
%define SQ_color_g                  16
%define SQ_color_b                  20
%define SQ_angle                    24
%define SQ_direction_timer          28
%define SQ_direction_change_int     32
%define SQ_speed                    36
%define SQ_lifespan                 40
%define SQ_age                      44
%define SQ_BYTES                    48

; struct List { void** items; int count; int cap; ...runtime-managed... }
; layout opaque to this file (helpers used).

; struct Event { int type; ... }
%define EVT_type                    0
%define PYGAME_QUIT                 256

section .bss
screen_ptr           resq 1
clock_ptr            resq 1
font_ptr             resq 1
running_flag         resd 1
random_bg_r          resd 1
random_bg_g          resd 1
random_bg_b          resd 1
event_buf            resb 64
squares_list         resb 32
new_squares_list     resb 32

section .text
global main

; ============================================================================
; Square* Square_new(int size)
; Python mapping: Square.__init__(size)
; ============================================================================
Square_new:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    ; in: edi=size
    mov [rbp-4], edi

    mov edi, SQ_BYTES
    call rt_malloc
    mov rbx, rax                       ; rbx = self*

    ; self.size = size
    mov eax, [rbp-4]
    mov [rbx + SQ_size], eax

    ; self.x = randint(0, SCREEN_WIDTH - size)
    xor edi, edi
    mov eax, [SCREEN_WIDTH]
    sub eax, [rbx + SQ_size]
    mov esi, eax
    call rand_int_range
    cvtsi2ss xmm0, eax
    movss [rbx + SQ_x], xmm0

    ; self.y = randint(0, SCREEN_HEIGHT - size)
    xor edi, edi
    mov eax, [SCREEN_HEIGHT]
    sub eax, [rbx + SQ_size]
    mov esi, eax
    call rand_int_range
    cvtsi2ss xmm0, eax
    movss [rbx + SQ_y], xmm0

    ; self.color = (randint(50,255), randint(50,255), randint(50,255))
    mov edi, 50
    mov esi, 255
    call rand_int_range
    mov [rbx + SQ_color_r], eax

    mov edi, 50
    mov esi, 255
    call rand_int_range
    mov [rbx + SQ_color_g], eax

    mov edi, 50
    mov esi, 255
    call rand_int_range
    mov [rbx + SQ_color_b], eax

    ; self.angle = uniform(0, 2*pi)
    movss xmm0, [ZERO_F]
    movss xmm1, [TWO_PI]
    call rand_float_range
    movss [rbx + SQ_angle], xmm0

    ; self.direction_timer = 0.0
    movss xmm0, [ZERO_F]
    movss [rbx + SQ_direction_timer], xmm0

    ; self.direction_change_interval = uniform(0.8, 2.0)
    mov eax, 0x3f4ccccd                ; 0.8f
    movd xmm0, eax
    mov eax, 0x40000000                ; 2.0f
    movd xmm1, eax
    call rand_float_range
    movss [rbx + SQ_direction_change_int], xmm0

    ; size_ratio = (size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
    ; speed = MAX_SPEED * (1 - size_ratio)
    mov eax, [rbx + SQ_size]
    sub eax, [MIN_SIZE_CONST]
    cvtsi2ss xmm0, eax
    mov eax, [MAX_SIZE_CONST]
    sub eax, [MIN_SIZE_CONST]
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1                    ; xmm0=size_ratio
    movss xmm1, [ONE_F]
    subss xmm1, xmm0                    ; 1-size_ratio
    mulss xmm1, [MAX_SPEED]
    movss [rbx + SQ_speed], xmm1

    ; self.lifespan = randint(30, 180)
    mov edi, 30
    mov esi, 180
    call rand_int_range
    mov [rbx + SQ_lifespan], eax

    ; self.age = 0.0
    movss xmm0, [ZERO_F]
    movss [rbx + SQ_age], xmm0

    mov rax, rbx
    leave
    ret

; ============================================================================
; void Square_compute_flee_vector(Square* self, List* all, float* out_dx, out_dy)
; Python mapping: compute_flee_vector()
; ============================================================================
Square_compute_flee_vector:
    ; rdi=self, rsi=list*, rdx=&out_dx, rcx=&out_dy
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx

    movss xmm0, [ZERO_F]
    movss [rdx], xmm0
    movss [rcx], xmm0

    xor r12d, r12d                      ; i=0
.flee_loop:
    mov rdi, [rbp-16]
    call rt_len
    cmp r12d, eax
    jge .flee_done

    mov rdi, [rbp-16]
    mov esi, r12d
    call rt_list_get                    ; rax=other
    mov r13, rax

    cmp r13, [rbp-8]                    ; if other is self: continue
    je .flee_next

    ; dx = self.x - other.x ; dy = self.y - other.y
    mov rbx, [rbp-8]
    movss xmm0, [rbx + SQ_x]
    subss xmm0, [r13 + SQ_x]            ; dx
    movss [rbp-36], xmm0

    movss xmm1, [rbx + SQ_y]
    subss xmm1, [r13 + SQ_y]            ; dy
    movss [rbp-40], xmm1

    ; dist = sqrt(dx*dx + dy*dy)
    movss xmm2, [rbp-36]
    mulss xmm2, xmm2
    movss xmm3, [rbp-40]
    mulss xmm3, xmm3
    addss xmm2, xmm3
    movss xmm0, xmm2
    call sqrtf
    movss [rbp-44], xmm0                ; dist

    ; if other.size > self.size and 0 < dist < DANGER_DISTANCE
    mov eax, [r13 + SQ_size]
    cmp eax, [rbx + SQ_size]
    jle .flee_next

    movss xmm0, [rbp-44]
    ucomiss xmm0, [ZERO_F]
    jbe .flee_next
    ucomiss xmm0, [DANGER_DISTANCE]
    jae .flee_next

    ; strength = 1 - dist/DANGER_DISTANCE
    movss xmm1, [rbp-44]
    divss xmm1, [DANGER_DISTANCE]
    movss xmm2, [ONE_F]
    subss xmm2, xmm1                    ; strength in xmm2

    ; flee_dx += (dx/dist)*strength
    mov rdx, [rbp-24]
    movss xmm3, [rbp-36]
    divss xmm3, [rbp-44]
    mulss xmm3, xmm2
    addss xmm3, [rdx]
    movss [rdx], xmm3

    ; flee_dy += (dy/dist)*strength
    mov rcx, [rbp-32]
    movss xmm4, [rbp-40]
    divss xmm4, [rbp-44]
    mulss xmm4, xmm2
    addss xmm4, [rcx]
    movss [rcx], xmm4

.flee_next:
    inc r12d
    jmp .flee_loop

.flee_done:
    leave
    ret

; ============================================================================
; void Square_compute_chase_vector(Square* self, List* all, float* out_dx, out_dy)
; Python mapping: compute_chase_vector()
; ============================================================================
Square_compute_chase_vector:
    ; rdi=self, rsi=list*, rdx=&out_dx, rcx=&out_dy
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx

    movss xmm0, [ZERO_F]
    movss [rdx], xmm0
    movss [rcx], xmm0

    xor r12d, r12d
.chase_loop:
    mov rdi, [rbp-16]
    call rt_len
    cmp r12d, eax
    jge .chase_done

    mov rdi, [rbp-16]
    mov esi, r12d
    call rt_list_get
    mov r13, rax

    cmp r13, [rbp-8]
    je .chase_next

    mov rbx, [rbp-8]
    movss xmm0, [rbx + SQ_x]
    subss xmm0, [r13 + SQ_x]
    movss [rbp-36], xmm0                ; dx

    movss xmm1, [rbx + SQ_y]
    subss xmm1, [r13 + SQ_y]
    movss [rbp-40], xmm1                ; dy

    movss xmm2, [rbp-36]
    mulss xmm2, xmm2
    movss xmm3, [rbp-40]
    mulss xmm3, xmm3
    addss xmm2, xmm3
    movss xmm0, xmm2
    call sqrtf
    movss [rbp-44], xmm0                ; dist

    ; if other.size < self.size and 0 < dist < DANGER_DISTANCE
    mov eax, [r13 + SQ_size]
    cmp eax, [rbx + SQ_size]
    jge .chase_next

    movss xmm0, [rbp-44]
    ucomiss xmm0, [ZERO_F]
    jbe .chase_next
    ucomiss xmm0, [DANGER_DISTANCE]
    jae .chase_next

    ; strength = 1 - dist/DANGER_DISTANCE
    movss xmm1, [rbp-44]
    divss xmm1, [DANGER_DISTANCE]
    movss xmm2, [ONE_F]
    subss xmm2, xmm1

    ; chase_dx += (dx/dist)*strength
    mov rdx, [rbp-24]
    movss xmm3, [rbp-36]
    divss xmm3, [rbp-44]
    mulss xmm3, xmm2
    addss xmm3, [rdx]
    movss [rdx], xmm3

    ; chase_dy += (dy/dist)*strength
    mov rcx, [rbp-32]
    movss xmm4, [rbp-40]
    divss xmm4, [rbp-44]
    mulss xmm4, xmm2
    addss xmm4, [rcx]
    movss [rcx], xmm4

.chase_next:
    inc r12d
    jmp .chase_loop

.chase_done:
    leave
    ret

; ============================================================================
; int Square_check_collision(Square* a, Square* b)
; Python mapping: _check_collision via pygame.Rect.colliderect
; Educational replacement: axis-aligned AABB overlap test
; ============================================================================
Square_check_collision:
    ; rdi=a, rsi=b -> eax=0/1
    ; if (a.x < b.x+b.size) && (a.x+a.size > b.x) &&
    ;    (a.y < b.y+b.size) && (a.y+a.size > b.y)
    push rbp
    mov rbp, rsp

    ; a.x < b.x + b.size
    movss xmm0, [rdi + SQ_x]
    movss xmm1, [rsi + SQ_x]
    mov eax, [rsi + SQ_size]
    cvtsi2ss xmm2, eax
    addss xmm1, xmm2
    ucomiss xmm0, xmm1
    jae .no

    ; a.x + a.size > b.x
    movss xmm0, [rdi + SQ_x]
    mov eax, [rdi + SQ_size]
    cvtsi2ss xmm2, eax
    addss xmm0, xmm2
    movss xmm1, [rsi + SQ_x]
    ucomiss xmm0, xmm1
    jbe .no

    ; a.y < b.y + b.size
    movss xmm0, [rdi + SQ_y]
    movss xmm1, [rsi + SQ_y]
    mov eax, [rsi + SQ_size]
    cvtsi2ss xmm2, eax
    addss xmm1, xmm2
    ucomiss xmm0, xmm1
    jae .no

    ; a.y + a.size > b.y
    movss xmm0, [rdi + SQ_y]
    mov eax, [rdi + SQ_size]
    cvtsi2ss xmm2, eax
    addss xmm0, xmm2
    movss xmm1, [rsi + SQ_y]
    ucomiss xmm0, xmm1
    jbe .no

    mov eax, 1
    leave
    ret

.no:
    xor eax, eax
    leave
    ret

; ============================================================================
; void Square_update(Square* self, List* all_squares, float dt)
; Python mapping: update()
; ============================================================================
Square_update:
    ; rdi=self, rsi=list*, xmm0=dt
    push rbp
    mov rbp, rsp
    sub rsp, 80
    mov [rbp-8], rdi                    ; self
    mov [rbp-16], rsi                   ; list
    movss [rbp-20], xmm0                ; dt

    ; direction_timer += dt
    mov rbx, [rbp-8]
    movss xmm1, [rbx + SQ_direction_timer]
    addss xmm1, [rbp-20]
    movss [rbx + SQ_direction_timer], xmm1

    ; if direction_timer >= direction_change_interval:
    ;   angle += uniform(-1,1)*0.8
    ;   direction_timer = 0
    ;   direction_change_interval = uniform(0.8,2.0)
    movss xmm2, [rbx + SQ_direction_timer]
    ucomiss xmm2, [rbx + SQ_direction_change_int]
    jb .skip_dir_change

    mov eax, 0xbf800000                 ; -1.0f
    movd xmm0, eax
    mov eax, 0x3f800000                 ; 1.0f
    movd xmm1, eax
    call rand_float_range
    mulss xmm0, [DIR_JITTER_SCALE]
    addss xmm0, [rbx + SQ_angle]
    movss [rbx + SQ_angle], xmm0

    movss xmm0, [ZERO_F]
    movss [rbx + SQ_direction_timer], xmm0

    mov eax, 0x3f4ccccd                 ; 0.8f
    movd xmm0, eax
    mov eax, 0x40000000                 ; 2.0f
    movd xmm1, eax
    call rand_float_range
    movss [rbx + SQ_direction_change_int], xmm0

.skip_dir_change:
    ; vx = cos(angle)*speed
    movss xmm0, [rbx + SQ_angle]
    call cosf
    mulss xmm0, [rbx + SQ_speed]
    movss [rbp-24], xmm0                ; vx

    ; vy = sin(angle)*speed
    movss xmm0, [rbx + SQ_angle]
    call sinf
    mulss xmm0, [rbx + SQ_speed]
    movss [rbp-28], xmm0                ; vy

    ; compute flee vector
    lea rdx, [rbp-32]                   ; flee_dx
    lea rcx, [rbp-36]                   ; flee_dy
    mov rdi, [rbp-8]
    mov rsi, [rbp-16]
    call Square_compute_flee_vector

    ; compute chase vector
    lea rdx, [rbp-40]                   ; chase_dx
    lea rcx, [rbp-44]                   ; chase_dy
    mov rdi, [rbp-8]
    mov rsi, [rbp-16]
    call Square_compute_chase_vector

    ; vx += flee_dx*120 ; vy += flee_dy*120
    movss xmm0, [rbp-32]
    mulss xmm0, [SCALE_FORCE]
    addss xmm0, [rbp-24]
    movss [rbp-24], xmm0

    movss xmm1, [rbp-36]
    mulss xmm1, [SCALE_FORCE]
    addss xmm1, [rbp-28]
    movss [rbp-28], xmm1

    ; vx -= chase_dx*120 ; vy -= chase_dy*120
    movss xmm0, [rbp-40]
    mulss xmm0, [SCALE_FORCE]
    movss xmm2, [rbp-24]
    subss xmm2, xmm0
    movss [rbp-24], xmm2

    movss xmm1, [rbp-44]
    mulss xmm1, [SCALE_FORCE]
    movss xmm3, [rbp-28]
    subss xmm3, xmm1
    movss [rbp-28], xmm3

    ; x += vx*dt ; y += vy*dt
    movss xmm0, [rbp-24]
    mulss xmm0, [rbp-20]
    addss xmm0, [rbx + SQ_x]
    movss [rbx + SQ_x], xmm0

    movss xmm1, [rbp-28]
    mulss xmm1, [rbp-20]
    addss xmm1, [rbx + SQ_y]
    movss [rbx + SQ_y], xmm1

    ; wrap horizontally:
    ; if x < 0 -> x = SCREEN_WIDTH - size
    ; elif x > SCREEN_WIDTH - size -> x = 0
    movss xmm0, [rbx + SQ_x]
    ucomiss xmm0, [ZERO_F]
    jae .x_not_neg
    mov eax, [SCREEN_WIDTH]
    sub eax, [rbx + SQ_size]
    cvtsi2ss xmm1, eax
    movss [rbx + SQ_x], xmm1
    jmp .x_done
.x_not_neg:
    mov eax, [SCREEN_WIDTH]
    sub eax, [rbx + SQ_size]
    cvtsi2ss xmm1, eax
    movss xmm0, [rbx + SQ_x]
    ucomiss xmm0, xmm1
    jbe .x_done
    movss xmm2, [ZERO_F]
    movss [rbx + SQ_x], xmm2
.x_done:

    ; wrap vertically:
    ; if y < 0 -> y = SCREEN_HEIGHT - size
    ; elif y > SCREEN_HEIGHT - size -> y = 0
    movss xmm0, [rbx + SQ_y]
    ucomiss xmm0, [ZERO_F]
    jae .y_not_neg
    mov eax, [SCREEN_HEIGHT]
    sub eax, [rbx + SQ_size]
    cvtsi2ss xmm1, eax
    movss [rbx + SQ_y], xmm1
    jmp .y_done
.y_not_neg:
    mov eax, [SCREEN_HEIGHT]
    sub eax, [rbx + SQ_size]
    cvtsi2ss xmm1, eax
    movss xmm0, [rbx + SQ_y]
    ucomiss xmm0, xmm1
    jbe .y_done
    movss xmm2, [ZERO_F]
    movss [rbx + SQ_y], xmm2
.y_done:

    ; for square in all_squares:
    ;   if square is self: continue
    ;   if collision and self.size > square.size and self.size < MAX_GROWTH_SIZE:
    ;       square.lifespan = 0
    ;       self.size *= 1 + (square.size/MAX_SIZE)
    xor r12d, r12d
.collision_loop:
    mov rdi, [rbp-16]
    call rt_len
    cmp r12d, eax
    jge .update_done

    mov rdi, [rbp-16]
    mov esi, r12d
    call rt_list_get
    mov r13, rax                         ; other

    cmp r13, [rbp-8]
    je .collision_next

    mov rdi, [rbp-8]
    mov rsi, r13
    call Square_check_collision
    test eax, eax
    jz .collision_next

    mov rbx, [rbp-8]
    mov eax, [rbx + SQ_size]
    cmp eax, [r13 + SQ_size]
    jle .collision_next
    cmp eax, [MAX_GROWTH_SIZE]
    jge .collision_next

    ; other.lifespan = 0
    mov dword [r13 + SQ_lifespan], 0

    ; self.size *= (1 + other.size / MAX_SIZE)
    ; note: Python stores size numeric and multiplies by float; this maps to int truncation on store
    mov eax, [r13 + SQ_size]
    cvtsi2ss xmm0, eax
    mov eax, [MAX_SIZE_CONST]
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1
    addss xmm0, [ONE_F]                  ; factor
    mov eax, [rbx + SQ_size]
    cvtsi2ss xmm2, eax
    mulss xmm2, xmm0
    cvttss2si eax, xmm2
    mov [rbx + SQ_size], eax

.collision_next:
    inc r12d
    jmp .collision_loop

.update_done:
    leave
    ret

; ============================================================================
; void Square_draw(Square* self, screen*)
; Python mapping: draw()
; ============================================================================
Square_draw:
    ; rdi=self, rsi=screen
    push rbp
    mov rbp, rsp
    sub rsp, 24

    mov rbx, rdi
    mov rdi, rsi                         ; screen
    mov esi, [rbx + SQ_color_r]
    mov edx, [rbx + SQ_color_g]
    mov ecx, [rbx + SQ_color_b]
    cvttss2si r8d, [rbx + SQ_x]
    cvttss2si r9d, [rbx + SQ_y]
    mov eax, [rbx + SQ_size]
    mov [rsp+8], eax                     ; width
    mov [rsp+16], eax                    ; height
    call pygame_draw_rect

    leave
    ret

; ============================================================================
; main loop mapping of Python main()
; ============================================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; pygame.init()
    call pygame_init

    ; font = pygame.font.Font(None, 30)
    mov edi, 30
    call font_default_new
    mov [font_ptr], rax

    ; RANDOM_COLOUR = make_random_colour() once at startup
    xor edi, edi
    mov esi, 255
    call rand_int_range
    mov [random_bg_r], eax
    xor edi, edi
    mov esi, 255
    call rand_int_range
    mov [random_bg_g], eax
    xor edi, edi
    mov esi, 255
    call rand_int_range
    mov [random_bg_b], eax

    ; screen = set_mode((800,600)); caption
    mov edi, [SCREEN_WIDTH]
    mov esi, [SCREEN_HEIGHT]
    call pygame_display_set_mode
    mov [screen_ptr], rax

    lea rdi, [WINDOW_TITLE]
    call pygame_display_set_caption

    ; clock = pygame.time.Clock()
    call pygame_clock_new
    mov [clock_ptr], rax

    ; squares = []
    lea rdi, [squares_list]
    call rt_list_init
    lea rdi, [new_squares_list]
    call rt_list_init

    ; for _ in range(5): squares.append(Square(25))
    mov ecx, 5
.add_big_loop:
    test ecx, ecx
    jz .add_mid_start
    mov edi, 25
    call Square_new
    lea rdi, [squares_list]
    mov rsi, rax
    call rt_list_append
    dec ecx
    jmp .add_big_loop

.add_mid_start:
    ; for _ in range(10): squares.append(Square(10))
    mov ecx, 10
.add_mid_loop:
    test ecx, ecx
    jz .add_small_start
    mov edi, 10
    call Square_new
    lea rdi, [squares_list]
    mov rsi, rax
    call rt_list_append
    dec ecx
    jmp .add_mid_loop

.add_small_start:
    ; for _ in range(30): squares.append(Square(4))
    mov ecx, 30
.add_small_loop:
    test ecx, ecx
    jz .run_start
    mov edi, 4
    call Square_new
    lea rdi, [squares_list]
    mov rsi, rax
    call rt_list_append
    dec ecx
    jmp .add_small_loop

.run_start:
    mov dword [running_flag], 1

; while running:
.frame_loop:
    cmp dword [running_flag], 1
    jne .shutdown

    ; dt = clock.tick(FPS) / 1000.0
    mov rdi, [clock_ptr]
    mov esi, [FPS_CONST]
    call pygame_clock_tick               ; eax=milliseconds
    cvtsi2ss xmm0, eax
    divss xmm0, [DT_DIVISOR_MS]
    movss [rbp-4], xmm0                  ; local dt

    ; event loop: if QUIT => running=False
.event_poll_loop:
    lea rdi, [event_buf]
    call pygame_event_poll
    test eax, eax
    jz .event_done
    mov eax, [event_buf + EVT_type]
    cmp eax, PYGAME_QUIT
    jne .event_poll_loop
    mov dword [running_flag], 0
    jmp .event_done
.event_done:

    ; for square in squares: square.update(squares, dt)
    xor r12d, r12d
.update_each_loop:
    lea rdi, [squares_list]
    call rt_len
    cmp r12d, eax
    jge .draw_bg
    lea rdi, [squares_list]
    mov esi, r12d
    call rt_list_get
    ; rax = square*
    mov rdi, rax
    lea rsi, [squares_list]
    movss xmm0, [rbp-4]
    call Square_update
    inc r12d
    jmp .update_each_loop

.draw_bg:
    ; screen.fill(RANDOM_COLOUR)
    mov rdi, [screen_ptr]
    mov esi, [random_bg_r]
    mov edx, [random_bg_g]
    mov ecx, [random_bg_b]
    call pygame_screen_fill_rgb

    ; for square in squares: square.draw(screen)
    xor r12d, r12d
.draw_each_loop:
    lea rdi, [squares_list]
    call rt_len
    cmp r12d, eax
    jge .rebuild_begin
    lea rdi, [squares_list]
    mov esi, r12d
    call rt_list_get
    mov rdi, rax
    mov rsi, [screen_ptr]
    call Square_draw
    inc r12d
    jmp .draw_each_loop

.rebuild_begin:
    ; new_squares = []
    lea rdi, [new_squares_list]
    call rt_list_clear

    ; for square in squares:
    ;   square.age += dt
    ;   if age < lifespan: append same
    ;   else: append Square(int(square.size))
    xor r12d, r12d
.rebuild_loop:
    lea rdi, [squares_list]
    call rt_len
    cmp r12d, eax
    jge .swap_lists

    lea rdi, [squares_list]
    mov esi, r12d
    call rt_list_get
    mov r13, rax                          ; square

    ; age += dt
    movss xmm0, [r13 + SQ_age]
    addss xmm0, [rbp-4]
    movss [r13 + SQ_age], xmm0

    ; if age < lifespan
    mov eax, [r13 + SQ_lifespan]
    cvtsi2ss xmm1, eax
    ucomiss xmm0, xmm1
    jae .respawn_square

    ; keep old square
    lea rdi, [new_squares_list]
    mov rsi, r13
    call rt_list_append
    jmp .rebuild_next

.respawn_square:
    ; Square(int(square.size))
    mov edi, [r13 + SQ_size]
    call Square_new
    lea rdi, [new_squares_list]
    mov rsi, rax
    call rt_list_append

.rebuild_next:
    inc r12d
    jmp .rebuild_loop

.swap_lists:
    ; squares = new_squares
    lea rdi, [squares_list]
    lea rsi, [new_squares_list]
    call rt_list_swap

    ; Debug text:
    ; number_of_squares = font.render(f"{len(squares)} squares", True, 'Black')
    lea rdi, [squares_list]
    call rt_len
    lea rdi, [TXT_FMT_SQUARES]
    mov esi, eax
    call fmt_int_to_text                  ; rax=char*
    mov rsi, rax
    mov rdi, [font_ptr]
    mov edx, 1                            ; antialias True
    mov ecx, [BLACK_R]
    mov r8d, [BLACK_G]
    mov r9d, [BLACK_B]
    call font_render_text                 ; rax=surface*
    mov r14, rax
    mov rdi, [screen_ptr]
    mov rsi, r14
    mov edx, 50
    mov ecx, 20
    call screen_blit

    ; actual_fps = font.render(f"FPS: {clock.get_fps():.3f}", True, 'Black')
    mov rdi, [clock_ptr]
    call pygame_clock_get_fps             ; xmm0=fps
    lea rdi, [TXT_FMT_FPS]
    call fmt_float3_to_text               ; rax=char*
    mov rsi, rax
    mov rdi, [font_ptr]
    mov edx, 1
    mov ecx, [BLACK_R]
    mov r8d, [BLACK_G]
    mov r9d, [BLACK_B]
    call font_render_text
    mov r15, rax
    mov rdi, [screen_ptr]
    mov rsi, r15
    mov edx, 50
    mov ecx, 50
    call screen_blit

    ; pygame.display.flip()
    call pygame_display_flip
    jmp .frame_loop

.shutdown:
    ; pygame.quit()
    call pygame_quit
    xor eax, eax
    leave
    ret