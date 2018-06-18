
  bits 16
  org 0x7c00

  SERIAL_PORT equ 0x3f8
  atapio_buf16 equ 0x500
  lba equ 0x504
  boot_disk equ 0x508
  dap equ 0x50c

	cli
  mov ax, 0
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  jmp 0:segments_set_up
segments_set_up:
	mov sp, 0x7c00

  mov [boot_disk], dl

	call serial_setup16

  mov si, str_hello
  call print_string16

  ;; Check int 0x13 extensions
  mov si, str_check_13_exts
  call print_string16
  mov ah, 0x41
  mov bx, 0x55aa
  mov dl, 0x80
  int 0x13
  jc error16

  mov si, str_boot_disk
  call print_string16
  mov al, [boot_disk]
  call print_hex_char
  mov si, str_newline
  call print_string16

  mov si, str_loading
  call print_string16

  mov DWORD [atapio_buf16], 0x7e00
  mov DWORD [lba], 1

load_stage2:
  mov dl, [boot_disk]
  mov bx, [atapio_buf16]
  mov ax, [lba]
  call read_sector
  jc error16
	mov si, str_dot
	call print_string16

  mov di, [atapio_buf16]
  add WORD [atapio_buf16], 512
  add WORD [lba], 1

  ;; The constant 0x706f7473 ("stop" in little endian) is used
  ;; to mark when to stop loading
  cmp DWORD [di], 0x706f7473
  je boot_stage2
  jmp load_stage2

boot_stage2:
	mov si, str_newline
	call print_string16
  mov si, str_booting
  call print_string16

  jmp stage2

  ;; Drive number in DL, sector number in AX, destination in ES:BX
  ;; Set CF on error
read_sector:
  mov byte [dap], 16
  mov byte [dap+1], 0
  mov word [dap+2], 1
  mov word [dap+4], bx
  mov word [dap+6], es
  mov word [dap+8], ax
  mov word [dap+10], 0
  mov dword [dap+12], 0
  mov si, dap
  mov ah, 0x42
  int 0x13
  ret

  ;; Print character in AL
print_char16:
  call serial_write_char16
  mov ah, 0x0e
  mov bx, 0x00
  mov bl, 0x07
  int 0x10
  ret

;; Print string pointed by SI
print_string16:
  mov al, [si]
  inc si
  or al, al
  jz print_string16_ret
  call print_char16
  jmp print_string16
print_string16_ret:
  ret

print_hex_nibble:
  and al, 0xf
  cmp al, 0xa
  jl print_hex_nibble_decimal
  add al, 'a' - 10
  jmp print_hex_nibble_print
print_hex_nibble_decimal:
  add al, '0'
print_hex_nibble_print:
  call print_char16
  ret

print_hex_char:
  mov cl, al
  shr al, 4
  call print_hex_nibble
  mov al, cl
  call print_hex_nibble
  ret

error16:
	mov si, str_panic
  call print_string16
  jmp $

	;; void serial_setup()
serial_setup16:
	;; Send command as indicated in https://wiki.osdev.org/Serial_Port
	mov dx, SERIAL_PORT + 1
	mov ax, 0x00
	out dx, al

	mov dx, SERIAL_PORT + 3
	mov ax, 0x80
	out dx, al

	mov dx, SERIAL_PORT
	mov ax, 0x03
	out dx, al

	mov dx, SERIAL_PORT + 1
	mov ax, 0x00
	out dx, al

	mov dx, SERIAL_PORT + 3
	mov ax, 0x03
	out dx, al

	mov dx, SERIAL_PORT + 2
	mov ax, 0xc7
	out dx, al

	mov dx, SERIAL_PORT + 4
	mov ax, 0x0b
	out dx, al

	ret


	;; void serial_write_char16(al)
  ;; AL is preserved
serial_write_char16:
	mov bl, al

	;; Test until the serial is available for transmit
	mov dx, SERIAL_PORT + 5
	in al, dx
  and ax, 0x20
	cmp ax, 0
	je serial_write_char16

	;; Actually write the char
	mov dx, SERIAL_PORT
  mov al, bl
	out dx, al

	ret


str_hello:
  db 'Hello, entered stage1!', 0xa, 0xd, 0
str_panic:
  db 'PANIC!', 0xa, 0xd, 0
str_loading:
  db 'Loading stage2', 0
str_dot:
  db '.', 0
str_newline:
  db 0xa, 0xd, 0
str_booting:
  db 'Booting stage2...', 0xa, 0xd, 0
str_boot_disk:
  db 'Booting from BIOS disk: ', 0
str_check_13_exts:
  db 'Checking for int 0x13 extensions...', 0xa, 0xd, 0

times 510 - ($ - $$) db 0
dw 0xAA55

stage2:
mov si, str_stage2
call print_string16

mov si, str_test_a20
call print_string16
call check_a20
cmp ax, 1
je a20_is_enabled
mov si, str_failed
call print_string16

mov si, str_enabling_bios
call print_string16
call enable_a20_bios

mov si, str_test_a20
call print_string16
call check_a20
cmp ax, 1
je a20_is_enabled
mov si, str_failed
call print_string16

mov si, str_enabling_kbd
call print_string16
call enable_a20_kbd

mov si, str_test_a20
call print_string16
call check_a20
cmp ax, 1
je a20_is_enabled
mov si, str_failed
call print_string16

jmp error16

a20_is_enabled:
mov si, str_ok
call print_string16

mov si, str_enabling_protected
call print_string16

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

  ;; cli

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

bits 32

enter_protected:
mov ax, 0x10
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

	mov esi, str_other_side
	call print_string

	call atapio_identify

	mov esi, str_reading_payload
	call print_string

mov DWORD [atapio_buf], 0x100000

load_payload_loop:
push DWORD [lba]
call atapio_read_sector
add esp, 4
cmp eax, 0
je payload_failed

	mov esi, str_dot
	call print_string

add DWORD [lba], 1
add DWORD [atapio_buf], 512

cmp DWORD [atapio_buf], 0x200000
ja payload_loaded

jmp load_payload_loop

payload_failed:
	mov esi, str_ex
	call print_string

	mov esi, str_newline
	call print_string

	mov esi, str_failed_payload
	call print_string

payload_loaded:
	mov esi, str_newline
	call print_string

	mov esi, str_chainloading
	call print_string

  jmp 0x100000

;; Print string pointed by ESI
print_string:
mov al, [esi]
inc esi
or al, al
jz print_string_ret
call serial_write_char
jmp print_string
print_string_ret:
ret

error:
	mov si, str_panic
        call print_string
        jmp $


	;; void serial_write_char(al)
serial_write_char:
	mov bl, al

	;; Test until the serial is available for transmit
	mov dx, SERIAL_PORT
	add dx, 5
	in al, dx
        and ax, 0x20
	cmp ax, 0
	je serial_write_char

	;; Actually write the char
	mov dx, SERIAL_PORT
        mov al, bl
	out dx, al

	ret


%include "atapio.asm"

platform_panic:
	jmp error


align 4

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

str_other_side:
db 'Hello there on the other side!', 0xa, 0
str_reading_payload:
db 'Loading payload', 0
str_failed_payload:
db 'Failed reading sector!', 0
str_chainloading:
db 'Chainloading payload, bye bye!', 0xa, 0
str_ex:
db 'X', 0

align 512
db 'stop'
align 512
