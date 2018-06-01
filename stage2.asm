
        bits 16
	org 0x7e00

mov si, str_stage2
call print_string

mov si, str_test_a20
call print_string
call check_a20
cmp ax, 1
je a20_is_enabled
mov si, str_failed
call print_string

mov si, str_enabling_bios
call print_string
call enable_a20_bios

mov si, str_test_a20
call print_string
call check_a20
cmp ax, 1
je a20_is_enabled
mov si, str_failed
call print_string

mov si, str_enabling_kbd
call print_string
call enable_a20_kbd

mov si, str_test_a20
call print_string
call check_a20
cmp ax, 1
je a20_is_enabled
mov si, str_failed
call print_string

jmp error

a20_is_enabled:
mov si, str_ok
call print_string

mov si, str_enabling_protected
call print_string

mov si, gdt_size
mov WORD [si], gdt_end
sub WORD [si], gdt
mov si, gdt_offset
mov DWORD [si], gdt
lgdt [gdt_desc]

mov eax, cr0
or al, 1
mov cr0, eax
jmp 0x8:enter_protected

enter_protected:
mov ax, 0x10
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

jmp end

gdt_desc:
gdt_size:
dw 0
gdt_offset:
dd 0

align 4

gdt:
; Null descriptor
dd 0
dd 0
; Code descriptor
dw 0xffff
dw 0x0000
db 0x00
db 10011010b  ; Access byte
db 11001111b  ; First nibble is flags
db 0x00
; Data descriptor
dw 0xffff
dw 0x0000
db 0x00
db 10010010b  ; Access byte
db 11001111b  ; First nibble is flags
db 0x00
gdt_end:

str_stage2:
db 'Entered stage2!', 0xa, 0xd, 0
str_panic:
db 'PANIC!', 0xa, 0xd, 0
str_test_a20:
db 'Testing whether A20 is enabled... ', 0
str_ok:
db 'OK!', 0xa, 0xd, 0
str_failed:
db 'failed', 0xa, 0xd, 0
str_enabling_bios:
db 'Enabling A20 via BIOS...', 0xa, 0xd, 0
str_enabling_kbd:
db 'Enabling A20 via keyboard controller...', 0xa, 0xd, 0
str_enabling_protected:
db 'Enabling protected mode, see you on the other side!', 0xa, 0xd, 0

;; Print character in AL
print_char:
mov ah, 0x0e
mov bx, 0x00
mov bl, 0x07
int 0x10
ret

;; Print string pointer by SI
print_string:
mov al, [si]
inc si
or al, al
jz print_string_ret
call print_char
jmp print_string
print_string_ret:
ret

error:
        mov si, str_panic
        call print_string
        jmp $

; Function: check_a20
;
; Purpose: to check the status of the a20 line in a completely self-contained state-preserving way.
;          The function can be modified as necessary by removing push's at the beginning and their
;          respective pop's at the end if complete self-containment is not required.
;
; Returns: 0 in ax if the a20 line is disabled (memory wraps around)
;          1 in ax if the a20 line is enabled (memory does not wrap around)

check_a20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax ; ax = 0
    mov es, ax

    not ax ; ax = 0xFFFF
    mov ds, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je check_a20__exit

    mov ax, 1

check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf

    ret

enable_a20_kbd:
        ;cli

        call    a20wait
        mov     al,0xAD
        out     0x64,al

        call    a20wait
        mov     al,0xD0
        out     0x64,al

        call    a20wait2
        in      al,0x60
        push    eax

        call    a20wait
        mov     al,0xD1
        out     0x64,al

        call    a20wait
        pop     eax
        or      al,2
        out     0x60,al

        call    a20wait
        mov     al,0xAE
        out     0x64,al

        call    a20wait
        ;sti
        ret

a20wait:
        in      al,0x64
        test    al,2
        jnz     a20wait
        ret


a20wait2:
        in      al,0x64
        test    al,1
        jz      a20wait2
        ret

enable_a20_bios:
mov     ax,2403h                ;--- A20-Gate Support ---
int     15h
jb      a20_ns                  ;INT 15h is not supported
cmp     ah,0
jnz     a20_ns                  ;INT 15h is not supported

mov     ax,2402h                ;--- A20-Gate Status ---
int     15h
jb      a20_failed              ;couldn't get status
cmp     ah,0
jnz     a20_failed              ;couldn't get status

cmp     al,1
jz      a20_activated           ;A20 is already activated

mov     ax,2401h                ;--- A20-Gate Activate ---
int     15h
jb      a20_failed              ;couldn't activate the gate
cmp     ah,0
jnz     a20_failed              ;couldn't activate the gate

a20_ns:
a20_failed:
mov al, 0
ret

a20_activated:
mov al, 1
ret

align 512
end:
