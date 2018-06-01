bits 16
org 0x7c00

	cli
	mov sp, 0x7c00

mov si, str_hello
call print_string

mov si, str_loading
call print_string

load_stage2:
        mov si, dapack
        mov ah, 0x42
        mov dl, 0x80
        int 0x13
        jc error
        mov si, sect_num
        cmp WORD [si], 1
        jne error

mov si, dest_off
mov di, [si]
add WORD [si], 512
mov si, lba
add WORD [si], 1

; The constant 0x706f7473 ("stop" in little endian) is used
; to mark when to stop loading
cmp DWORD [di], 0x706f7473
je boot_stage2
jmp load_stage2

boot_stage2:
        mov si, str_booting
        call print_string

; Save the number of blocks read
mov si, lba
mov bx, [si]
        jmp 0x7e00

dapack:
        db 16
        db 0
sect_num:
        dw 1
dest_off:
        dw 0x7e00
dest_seg:
        dw 0
lba:
        dd 1
        dd 0

str_hello:
db 'Hello, entered stage1!', 0xa, 0xd, 0
str_panic:
db 'PANIC!', 0xa, 0xd, 0
str_loading:
db 'Loading stage2...', 0xa, 0xd, 0
str_booting:
db 'Booting stage2...', 0xa, 0xd, 0

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

times 510 - ($ - $$) db 0
dw 0xAA55
