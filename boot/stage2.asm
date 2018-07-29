;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
;; https://gitlab.com/giomasce/asmc

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

  ;; This file includes snippets taken from http://wiki.osdev.org; by
  ;; https://wiki.osdev.org/OSDev_Wiki:Copyrights they are to be
  ;; considered in the public domain, or that the CC0 license applies, so
  ;; their inclusion in a GPL-3+ project should be ok.

stage2:
  ;; Check if A20 is enabled and try a few methods to enable it
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
  ;; A20 is enabled at last! Now let us tackle protected mode
  mov si, str_ok
  call print_string16

  mov si, str_enabling_protected
  call print_string16

  ;; Prepare and load a very simple GDT
  mov si, gdt_size
  mov WORD [si], gdt_end
  sub WORD [si], gdt
  mov si, gdt_offset
  mov DWORD [si], gdt
  lgdt [gdt_desc]

  ;; Enable protected mode (but not pagination)
  mov eax, cr0
  or al, 1
  mov cr0, eax
  jmp 0x8:enter_protected

  ;; The following snippet is taken from https://wiki.osdev.org/A20

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
  ;; We are finally in protected mode, we just need to reload the other segments
  mov ax, 0x10
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax

	mov esi, str_other_side
	call print_string

  ;; Check the hard disk
	call atapio_identify

	mov esi, str_reading_payload
	call print_string

  ;; And load the actual payload
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
  ;; The payload is finally loaded and we can jump into it!
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
error_loop:
  hlt
  jmp error_loop


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
db 'Into stage2!', 0xa, 0xd, 0
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
