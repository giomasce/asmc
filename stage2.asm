
        bits 16
	org 0x7e00

; Save the content of the LBA address where to read the operating system
mov si, next_lba
mov [si], bx

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
str_panic_:
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

next_lba:
dd 0

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
        mov si, str_panic_
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

bits 32

enter_protected:
mov ax, 0x10
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

call term_setup
push str_other_side
push 1
call platform_log
add esp, 8

call atapio_identify

push str_reading_payload
push 1
call platform_log
add esp, 8

push DWORD [next_lba]
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8

mov DWORD [atapio_buf], 0x100000

load_payload_loop:
push DWORD [next_lba]
call atapio_read_sector
add esp, 4
cmp eax, 0
je payload_failed

push '.'
push 1
call platform_write_char
add esp, 8

add DWORD [next_lba], 1
add DWORD [atapio_buf], 512

cmp DWORD [atapio_buf], 0x200000
ja payload_loaded

jmp load_payload_loop

payload_failed:
push 'X'
push 1
call platform_write_char
add esp, 8

push 0xa
push 1
call platform_write_char
add esp, 8

push str_failed_at
push 1
call platform_log
add esp, 8

push DWORD [next_lba]
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8

payload_loaded:
push 0xa
push 1
call platform_write_char
add esp, 8

jmp 0x100000

str_other_side:
db 'Hello there on the other side!', 0xa, 0
str_reading_payload:
db 'Reading payload from sector ', 0
str_failed_at:
db 'Failed reading at sector ', 0

%include "atapio.asm"



STACK_SIZE equ 65536
;; STACK_SIZE equ 8388608

TERM_ROW_NUM equ 25
TERM_COL_NUM equ 80
TERM_BASE_ADDR equ 0xb8000

MAX_OPEN_FILE_NUM equ 1024

MBMAGIC equ 0x1badb002
;; Set flags for alignment, memory map and load adds
MBFLAGS equ 0x10003
;; 0x100000000 - MBMAGIC - MBFLAGS
MBCHECKSUM equ 0xe4514ffb

;; MB_ENTRY_ADDR equ _start

;; Multiboot header
dd MBMAGIC
dd MBFLAGS
dd MBCHECKSUM

dd 0x100000
dd 0x100000
dd 0x0
dd 0x0
dd 0x100020

jmp start_from_multiboot

term_row:
resd 1

term_col:
resd 1

heap_ptr:
resd 1

open_files:
resd 1

open_file_num:
resd 1

write_mem_ptr:
resd 1

str_exit:
db 'The execution has finished, bye bye...'
db NEWLINE
db 0
str_panic:
db 'PANIC!'
db NEWLINE
db 0

str_init_heap_stack:
db 'Initializing heap and stack... '
db 0
str_init_files:
db 'Initializing files table... '
db 0
str_init_asm_symbols_table:
db 'Initializing symbols table... '
db 0
str_done:
db 'done!'
db NEWLINE
db 0

str_dump_multiboot:
db 'Dumping multiboot boot information...'
db NEWLINE
db 0
str_mem_lower:
db 'mem_lower = '
db 0
str_mem_upper:
db 'mem_lower = '
db 0
str_mmap:
db 'Memory region: '
db 0
str_slash:
db ' / '
db 0

str_END:
db 'END'
db 0

temp_stack:
resb 128
temp_stack_top:

start_from_multiboot:
;; Setup a temporary stack
mov esp, temp_stack_top
and esp, 0xfffffff0

;; Initialize terminal
call term_setup

;; Dump data from multiboot information structure
push ebx
call dump_multiboot
add esp, 4

;; Log
push str_init_heap_stack
push 1
call platform_log
add esp, 8

;; Find the end of the ar initrd
push 0
mov edx, esp
push 0
mov ecx, esp
push edx
push ecx
push str_END
call walk_initrd
add esp, 12
add esp, 4
pop ecx

;; Initialize the heap
mov eax, heap_ptr
sub ecx, 1
or ecx, 0xf
add ecx, 1
mov [eax], ecx

;; Allocate the stack on the heap
add ecx, STACK_SIZE
mov [eax], ecx
mov esp, ecx

;; Log
push str_done
push 1
call platform_log
add esp, 8

;; Log
push str_init_files
push 1
call platform_log
add esp, 8

;; Initialize file table
mov eax, open_file_num
mov DWORD [eax], 0
mov eax, MAX_OPEN_FILE_NUM
mov edx, 12
mul edx
push eax
call platform_allocate
add esp, 4
mov edx, open_files
mov [edx], eax

;; Log
push str_done
push 1
call platform_log
add esp, 8

;; Log
push str_init_asm_symbols_table
push 1
call platform_log
add esp, 8

;; Init symbol table
call init_symbols

;; Expose some kernel symbols
call init_kernel_api

;; Log
push str_done
push 1
call platform_log
add esp, 8

;; Call start
call start

call platform_exit


dump_multiboot:
push ebp
mov ebp, esp
push ebx
push esi

;; Save multiboot location
mov ebx, [ebp+8]

;; Log
push str_dump_multiboot
push 1
call platform_log
add esp, 8

;; Check mem_lower and mem_upper are supported
mov eax, [ebx]
test eax, 1
je dump_multiboot_mmap

;; Print mem_lower
push str_mem_lower
push 1
call platform_log
add esp, 8
mov eax, [ebx+4]
push eax
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8
push str_newline
push 1
call platform_log
add esp, 8

;; Print mem_upper
push str_mem_upper
push 1
call platform_log
add esp, 8
mov eax, [ebx+8]
push eax
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8
push str_newline
push 1
call platform_log
add esp, 8

dump_multiboot_mmap:
;; Check mmap_* are supported
mov eax, [ebx]
test eax, 64
je dump_multiboot_end

;; Save mmap buffer in registers
mov esi, [ebx+48]
mov ebx, [ebx+44]
add ebx, esi

dump_multiboot_mmap_dump:
;; Call mmap_dump
push esi
call mmap_dump
add esp, 4

;; Increment pointer
add esi, [esi]
add esi, 4

cmp esi, ebx
jb dump_multiboot_mmap_dump

dump_multiboot_end:
pop esi
pop ebx
pop ebp
ret


mmap_dump:
push ebp
mov ebp, esp
push ebx

mov ebx, [ebp+8]

;; Check that ignored fields are not used
cmp DWORD [ebx+8], 0
jne platform_panic
cmp DWORD [ebx+16], 0
jne platform_panic

;; Print size
;; push str_mmap_size
;; push 1
;; call platform_log
;; add esp, 8
;; mov eax, [ebx]
;; push eax
;; call itoa
;; add esp, 4
;; push eax
;; push 1
;; call platform_log
;; add esp, 8
;; push str_newline
;; push 1
;; call platform_log
;; add esp, 8

;; Print base_addr
;; push str_mmap_base_addr
;; push 1
;; call platform_log
;; add esp, 8
push str_mmap
push 1
call platform_log
add esp, 8
mov eax, [ebx+4]
push eax
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8
;; push str_newline
;; push 1
;; call platform_log
;; add esp, 8

;; Print length
;; push str_mmap_length
;; push 1
;; call platform_log
;; add esp, 8
push str_slash
push 1
call platform_log
add esp, 8
mov eax, [ebx+12]
push eax
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8
;; push str_newline
;; push 1
;; call platform_log
;; add esp, 8

;; Print type
;; push str_mmap_type
;; push 1
;; call platform_log
;; add esp, 8
push str_slash
push 1
call platform_log
add esp, 8
mov eax, [ebx+20]
push eax
call itoa
add esp, 4
push eax
push 1
call platform_log
add esp, 8
push str_newline
push 1
call platform_log
add esp, 8

pop ebx
pop ebp
ret


;; void term_setup()
term_setup:
;; Compute the size of the VGA framebuffer
mov eax, TERM_ROW_NUM
mov edx, TERM_COL_NUM
mul edx

;; Fill the VGA framebuffer with spaces char, with color light grey
;; 	on black
mov ecx, TERM_BASE_ADDR
term_setup_loop:
cmp eax, 0
je term_setup_after_loop
mov BYTE [ecx], SPACE
mov BYTE [ecx+1], 0x07
add ecx, 2
sub eax, 1
jmp term_setup_loop

term_setup_after_loop:
;; Set the cursor position
mov eax, term_row
mov DWORD [eax], 0
mov eax, term_col
mov DWORD [eax], 0

ret


;; void term_set_char(int row, int col, int char)
term_set_char:
;; Computer the character address
mov eax, [esp+4]
mov edx, TERM_COL_NUM
mul edx
add eax, [esp+8]
mov edx, 2
mul edx
add eax, TERM_BASE_ADDR

;; Store the new character
mov dl, [esp+12]
mov BYTE [eax], dl

ret


;; void term_shift()
term_shift:
push ebx

;; Compute the size of an entire row (stored in ecx)
mov eax, TERM_COL_NUM
mov edx, 2
mul edx
mov ecx, eax

;; Compute the size of all rows (stored in eax)
mov edx, TERM_ROW_NUM
mul edx

;; Store begin (ecx) and end (eax) of the buffer to copy, and the
;; pointer to which to copy (edx)
add ecx, TERM_BASE_ADDR
add eax, TERM_BASE_ADDR
mov edx, TERM_BASE_ADDR

;; Copy loop
term_shift_loop:
cmp ecx, eax
je term_shift_after_loop
mov bl, [ecx]
mov [edx], bl
add ecx, 1
add edx, 1
jmp term_shift_loop

term_shift_after_loop:
mov ecx, edx
mov eax, TERM_COL_NUM

;; Clear last line
term_shift_loop2:
cmp eax, 0
je term_shift_ret
mov BYTE [ecx], SPACE
mov BYTE [ecx+1], 0x07
sub eax, 1
add ecx, 2
jmp term_shift_loop2

term_shift_ret:
pop ebx
ret


;; void term_put_char(int char)
term_put_char:
;; If the character is a newline, jump to the newline code
mov ecx, [esp+4]
cmp cl, NEWLINE
je term_put_char_newline

;; Call term_set_char with the current position
push ecx
mov edx, term_col
mov eax, [edx]
push eax
mov edx, term_row
mov eax, [edx]
push eax
call term_set_char
add esp, 12

;; Advance of one character
mov edx, term_col
mov eax, [edx]
add eax, 1
mov [edx], eax

;; Check for column overflow
cmp eax, TERM_COL_NUM
jne term_put_char_finish

;; Move to the beginning of next row
term_put_char_newline:
mov edx, term_col
mov DWORD [edx], 0
mov edx, term_row
mov eax, [edx]
add eax, 1
mov [edx], eax

;; Check for row overflow
cmp eax, TERM_ROW_NUM
jne term_put_char_finish

;; Reset the row position and shift all lines
sub eax, 1
mov [edx], eax
call term_shift

term_put_char_finish:
ret


loop_forever:
jmp loop_forever


platform_exit:
;; Write an exit string
push str_exit
push 1
call platform_log
add esp, 8

jmp loop_forever


platform_panic:
;; Write an exit string
push str_panic
push 1
call platform_log
add esp, 8

jmp loop_forever


platform_write_char:
;; Switch depending on the requested file descriptor
mov eax, [esp+4]
cmp eax, 0
je platform_write_char_mem
cmp eax, 1
je platform_write_char_stdout
cmp eax, 2
je platform_write_char_stdout
ret

platform_write_char_mem:
;; Write to memory and update pointer
mov eax, [esp+8]
mov ecx, write_mem_ptr
mov edx, [ecx]
mov [edx], al
add edx, 1
mov [ecx], edx

;; Log (for debug)
;; push edx
;; call debug_log_itoa
;; add esp, 4
;; push str_newline
;; call debug_log
;; add esp, 4

ret

platform_write_char_stdout:
;; Send stdout to terminal
mov eax, [esp+8]
push eax
call term_put_char
add esp, 4
ret


platform_log:
;; Use ebx for the fd and esi for the string
mov eax, [esp+4]
mov edx, [esp+8]
push ebx
push esi
mov ebx, eax
mov esi, edx

;; Loop over the string and call platform_write_char
platform_log_loop:
mov ecx, 0
mov cl, [esi]
cmp cl, 0
je platform_log_loop_ret
push ecx
push ebx
call platform_write_char
add esp, 8
add esi, 1
jmp platform_log_loop

platform_log_loop_ret:
pop esi
pop ebx
ret


;; void *platform_allocate(int size)
platform_allocate:
;; Prepare to return the current heap_ptr
mov ecx, heap_ptr
mov eax, [ecx]

;; Add the new size to the heap_ptr and realign
mov edx, [esp+4]
add edx, eax
sub edx, 1
or edx, 0xf
add edx, 1
mov [ecx], edx

ret


platform_open_file:
;; Find the new file record
mov eax, open_file_num
mov eax, [eax]
mov edx, 12
mul edx
mov ecx, open_files
add eax, [ecx]

;; ;; Call walk_initrd
mov edx, [esp+4]
mov ecx, eax
add ecx, 8
push eax
push ecx
push eax
push edx
call walk_initrd
add esp, 12

;; Reset it to the beginning
pop eax
mov ecx, [eax]
mov [eax+4], ecx

;; Return and increment the open file number
mov ecx, open_file_num
mov eax, [ecx]
add DWORD [ecx], 1

ret


platform_reset_file:
;; Find the file record
mov eax, [esp+4]
mov edx, 12
mul edx
mov ecx, open_files
add eax, [ecx]

;; Reset it to the beginning
mov ecx, [eax]
mov [eax+4], ecx

ret


platform_read_char:
;; Find the file record
mov eax, [esp+4]
mov edx, 12
mul edx
mov ecx, open_files
add eax, [ecx]

;; Check if we are at the end
mov ecx, [eax+4]
cmp ecx, [eax+8]
je platform_read_char_eof

;; Return a character and increment pointer
mov edx, 0
mov dl, [ecx]
add DWORD [eax+4], 1
mov eax, edx
ret

platform_read_char_eof:
;; Return -1
mov eax, 0xffffffff
ret


str_platform_panic:
db 'platform_panic'
db 0
str_platform_exit:
db 'platform_exit'
db 0
str_platform_open_file:
db 'platform_open_file'
db 0
str_platform_read_char:
db 'platform_read_char'
db 0
str_platform_write_char:
db 'platform_write_char'
db 0
str_platform_log:
db 'platform_log'
db 0
str_platform_allocate:
db 'platform_allocate'
db 0
str_platform_get_symbol:
db 'platform_get_symbol'
db 0

;; Initialize the symbols table with the "kernel API"
init_kernel_api:
push 0
push platform_panic
push str_platform_panic
call add_symbol
add esp, 12

push 0
push platform_exit
push str_platform_exit
call add_symbol
add esp, 12

push 1
push platform_open_file
push str_platform_open_file
call add_symbol
add esp, 12

push 1
push platform_read_char
push str_platform_read_char
call add_symbol
add esp, 12

push 2
push platform_write_char
push str_platform_write_char
call add_symbol
add esp, 12

push 2
push platform_log
push str_platform_log
call add_symbol
add esp, 12

push 1
push platform_allocate
push str_platform_allocate
call add_symbol
add esp, 12

push 2
push platform_get_symbol
push str_platform_get_symbol
call add_symbol
add esp, 12

ret


;; int platform_get_symbol(char *name, int *arity)
;; similar as find_symbol, but panic if it does not exist; retuns
;; the location and put the arity in *arity if arity is not null
platform_get_symbol:
;; Call find_symbol
mov eax, [esp+4]
mov ecx, [esp+8]
push 0
mov edx, esp
push ecx
push edx
push eax
call find_symbol
add esp, 12

;; Panic if it does not exist
cmp eax, 0
je platform_panic

;; Return the symbol location
pop eax

ret

NEWLINE equ 0xa
SPACE equ 0x20
TAB equ 0x9
ZERO equ 0x30
NINE equ 0x39
LITTLEA equ 0x61
LITTLEF equ 0x66
LITTLEN equ 0x6e
LITTLET equ 0x74
LITTLEX equ 0x78
SQ_OPEN equ 0x5b
SQ_CLOSED equ 0x5d
PLUS equ 0x2b
APEX equ 0x27
COMMA equ 0x2c
SEMICOLON equ 0x3b
COLON equ 0x3a
DOT equ 0x2e
QUOTE equ 0x22
BACKSLASH equ 0x5c
POUND equ 0x23
DOLLAR equ 0x24
AMPERSAND equ 0x26
PERCENT equ 0x25
AT_SIGN equ 0x40

ITOA_BUF_LEN equ 32

INPUT_BUF_LEN equ 1024
MAX_SYMBOL_NAME_LEN equ 128
SYMBOL_TABLE_LEN equ 1024
;; SYMBOL_TABLE_SIZE = SYMBOL_TABLE_LEN * MAX_SYMBOL_NAME_LEN
SYMBOL_TABLE_SIZE equ 131072

itoa_buf:
resb ITOA_BUF_LEN

symbol_names_ptr:
resd 1

symbol_locs_ptr:
resd 1

symbol_arities_ptr:
resd 1

symbol_num:
resd 1

current_loc:
resd 1

stage:
resd 1

emit_fd:
resd 1

str_symbol_already_defined:
db 'Symbol already defined: '
db 0
str_check:
db 'CHECK'
db 0
str_newline:
db NEWLINE
db 0

global get_symbol_names
get_symbol_names:
mov eax, symbol_names_ptr
mov eax, [eax]
ret

global get_symbol_locs
get_symbol_locs:
mov eax, symbol_locs_ptr
mov eax, [eax]
ret

global get_symbol_arities
get_symbol_arities:
mov eax, symbol_arities_ptr
mov eax, [eax]
ret

global get_symbol_num
get_symbol_num:
mov eax, symbol_num
ret

global get_current_loc
get_current_loc:
mov eax, current_loc
ret

global get_stage
get_stage:
mov eax, stage
ret

global get_emit_fd
get_emit_fd:
mov eax, emit_fd
ret


debug_check:
push eax
push ecx
push edx

;; Log
push str_check
push 1
call platform_log
add esp, 8

pop edx
pop ecx
pop eax
ret


debug_log:
push ebp
mov ebp, esp
push eax
push ecx
push edx

;; Log
push DWORD [ebp+8]
push 1
call platform_log
add esp, 8

pop edx
pop ecx
pop eax
pop ebp
ret


debug_log_itoa:
push ebp
mov ebp, esp
push eax
push ecx
push edx

;; Itoa
push DWORD [ebp+8]
call itoa
add esp, 4

;; Log
push eax
push 1
call platform_log
add esp, 8

pop edx
pop ecx
pop eax
pop ebp
ret


;; char *itoa(int x)
global itoa
itoa:
;; Clear the buffer
mov ecx, ITOA_BUF_LEN
mov eax, itoa_buf

itoa_clear_loop:
cmp ecx, 0
je itoa_cleared
mov BYTE [eax], SPACE
add eax, 1
sub ecx, 1
jmp itoa_clear_loop

itoa_cleared:
;; Prepare registers
mov eax, [esp+4]
push esi
mov esi, 10
mov ecx, itoa_buf
add ecx, ITOA_BUF_LEN
sub ecx, 1

;; Store a terminator at the end
mov BYTE [ecx], 0
sub ecx, 1

itoa_loop:
;; Divide by the base
mov edx, 0
div esi

;; Output the remainder
add edx, ZERO
mov [ecx], dl

;; Check for termination
cmp eax, 0
je itoa_end

;; Move the pointer backwards
sub ecx, 1

jmp itoa_loop

itoa_end:
mov eax, ecx
pop esi
ret


global emit
emit:
;; Add 1 to the current location
mov edx, current_loc
add DWORD [edx], 1

;; If we are in stage 1, write the character
mov edx, stage
cmp DWORD [edx], 1
jne emit_ret
mov ecx, 0
mov cl, [esp+4]
mov edx, emit_fd
push ecx
push DWORD [edx]
call platform_write_char
add esp, 8

emit_ret:
ret


global emit32
emit32:
;; Emit each byte in order
mov eax, 0
mov al, [esp+4]
push eax
call emit
add esp, 4

mov eax, 0
mov al, [esp+5]
push eax
call emit
add esp, 4

mov eax, 0
mov al, [esp+6]
push eax
call emit
add esp, 4

mov eax, 0
mov al, [esp+7]
push eax
call emit
add esp, 4

ret


global emit_str
emit_str:
;; Check for termination
cmp DWORD [esp+8], 0
je emit_str_ret

;; Call emit
mov eax, [esp+4]
mov edx, 0
mov dl, [eax]
push edx
call emit
add esp, 4

;; Increment/decrement and repeat
add DWORD [esp+4], 1
sub DWORD [esp+8], 1
jmp emit_str

emit_str_ret:
ret


global decode_number
decode_number:
push ebp
mov ebp, esp
push ebx
push edi
push esi

;; Use eax for storing the result
mov eax, 0

;; Use ebx for storing the input string
mov ebx, [ebp+8]

;; Use esi to remember if we have seen at least one digit
mov esi, 0

;; Determine whether we work in base 10 (edi==1) or 16 (edi==0)
mov edi, 1
cmp BYTE [ebx], ZERO
jne decode_number_loop
cmp BYTE [ebx+1], LITTLEX
jne decode_number_loop
mov edi, 0
add ebx, 2

decode_number_loop:
;; Check if we have found the terminator
mov cl, [ebx]
cmp cl, 0
je decode_number_ret

;; If not, then we have seen at least one digit
mov esi, 1

;; Multiply the current result by 10 or 16 depending on edi
cmp edi, 1
jne decode_number_mult16
mov edx, 10
mul edx
jmp decode_number_after_mult
decode_number_mult16:
mov edx, 16
mul edx

decode_number_after_mult:
;; If we have a decimal digit, add it to the number
cmp cl, ZERO
jnae decode_number_after_decimal_digit
cmp cl, NINE
jnbe decode_number_after_decimal_digit
mov edx, 0
mov dl, cl
add eax, edx
sub eax, ZERO
jmp decode_number_finish_loop

decode_number_after_decimal_digit:
;; If we have an hexadecimal digit and we are in hexadecimal mode,
;; add it to the number
cmp edi, 0
jne decode_number_after_hex_digit
cmp cl, LITTLEA
jnae decode_number_after_hex_digit
cmp cl, LITTLEF
jnbe decode_number_after_hex_digit
mov edx, 0
mov dl, cl
add eax, edx
add eax, 10
sub eax, LITTLEA
jmp decode_number_finish_loop

decode_number_after_hex_digit:
mov esi, 0
jmp decode_number_ret

decode_number_finish_loop:
add ebx, 1
jmp decode_number_loop

decode_number_ret:
mov edx, [ebp+12]
mov [edx], eax
mov eax, esi
pop esi
pop edi
pop ebx
pop ebp
ret


;; int atoi(char*)
global atoi
atoi:
;; Call decode_number, adapting the parameters
mov ecx, [esp+4]
push 0
mov edx, esp
push edx
push ecx
call decode_number
add esp, 8
cmp eax, 0
pop eax
je platform_panic
ret


;; void *memcpy(void *dest, const void *src, int n)
global memcpy
memcpy:
;; Load registers
mov eax, [esp+4]
mov ecx, [esp+8]
mov edx, [esp+12]
push ebx

memcpy_loop:
;; Test for termination
cmp edx, 0
je memcpy_end

;; Copy one character
mov bl, [ecx]
mov [eax], bl

;; Decrease the counter and increase the pointers
sub edx, 1
add eax, 1
add ecx, 1

jmp memcpy_loop

memcpy_end:
pop ebx
ret


global init_symbols
init_symbols:
;; Allocate symbol names table
push SYMBOL_TABLE_SIZE
call platform_allocate
add esp, 4
mov ecx, symbol_names_ptr
mov [ecx], eax

;; Allocate symbol locations table
mov eax, SYMBOL_TABLE_LEN
mov edx, 4
mul eax
push eax
call platform_allocate
add esp, 4
mov ecx, symbol_locs_ptr
mov [ecx], eax

;; Allocate symbol arities table
mov eax, SYMBOL_TABLE_LEN
mov edx, 4
mul eax
push eax
call platform_allocate
add esp, 4
mov ecx, symbol_arities_ptr
mov [ecx], eax

;; Reset symbol_num
mov eax, symbol_num
mov DWORD [eax], 0

ret


global get_symbol_idx
get_symbol_idx:
;; Set up registers and stack
push ebp
mov ebp, esp
mov ecx, 0

get_symbol_idx_loop:
;; Check for termination
mov eax, symbol_num
cmp ecx, [eax]
je get_symbol_idx_end

;; Save ecx
push ecx

;; Compute and push the second argument to strcmp
mov edx, MAX_SYMBOL_NAME_LEN
mov eax, ecx
mul edx
mov ecx, symbol_names_ptr
add eax, [ecx]
push eax

;; Push the first argument
mov eax, [ebp+8]
push eax

;; Call strcmp, clean the stack and restore ecx
call strcmp
add esp, 8
pop ecx

;; If strcmp returned 0, then we return
cmp eax, 0
je get_symbol_idx_end

;; Increment ecx and check for termination
add ecx, 1
jmp get_symbol_idx_loop

get_symbol_idx_end:
mov eax, ecx
pop ebp
ret


global find_symbol
find_symbol:
;; Set up registers and stack
push ebp
mov ebp, esp

;; Call get_symbol_idx
push DWORD [ebp+8]
call get_symbol_idx
add esp, 4
mov ecx, eax
mov eax, symbol_num
cmp ecx, [eax]
je find_symbol_not_found

;; If the second argument is not null, fill it with the location
mov edx, [ebp+12]
cmp edx, 0
je find_symbol_arity
mov eax, 4
mul ecx
mov edx, symbol_locs_ptr
add eax, [edx]
mov eax, [eax]
mov edx, [ebp+12]
mov [edx], eax

find_symbol_arity:
;; If the third argument is not null, fill it with the arity
mov edx, [ebp+16]
cmp edx, 0
je find_symbol_ret_found
mov eax, 4
mul ecx
mov edx, symbol_arities_ptr
add eax, [edx]
mov eax, [eax]
mov edx, [ebp+16]
mov [edx], eax

find_symbol_ret_found:
mov eax, 1
jmp find_symbol_ret

find_symbol_not_found:
mov eax, 0
jmp find_symbol_ret

find_symbol_ret:
pop ebp
ret


global add_symbol
add_symbol:
push ebp
mov ebp, esp
push ebx

;; Call strlen
mov eax, [ebp+8]
push eax
call strlen
add esp, 4

;; Check input length
cmp eax, 0
jna platform_panic
cmp eax, MAX_SYMBOL_NAME_LEN
jnb platform_panic

;; Call find_symbol and check the symbol does not exist yet
push 0
push 0
push DWORD [ebp+8]
call find_symbol
add esp, 12
cmp eax, 0
jne add_symbol_already_defined

;; Put the current symbol number in ebx and check it is not
;; overflowing
mov eax, symbol_num
mov ebx, [eax]
cmp ebx, SYMBOL_TABLE_LEN
jnb platform_panic

;; Save the location for the new symbol
mov eax, ebx
mov ecx, 4
mul ecx
mov ecx, symbol_locs_ptr
add eax, [ecx]
mov ecx, [ebp+12]
mov [eax], ecx

;; Save the arity for the new symbol
mov eax, ebx
mov ecx, 4
mul ecx
mov ecx, symbol_arities_ptr
add eax, [ecx]
mov ecx, [ebp+16]
mov [eax], ecx

;; Save the name for the new symbol
mov eax, [ebp+8]
push eax
mov eax, ebx
mov ecx, MAX_SYMBOL_NAME_LEN
mul ecx
mov ecx, symbol_names_ptr
add eax, [ecx]
push eax
call strcpy
add esp, 8

;; Increment and store the new symbol number
add ebx, 1
mov eax, symbol_num
mov [eax], ebx

pop ebx
pop ebp
ret

add_symbol_already_defined:
;; Log
push str_symbol_already_defined
push 1
call platform_log
add esp, 8
push DWORD [ebp+8]
push 1
call platform_log
add esp, 8
push str_newline
push 1
call platform_log
add esp, 8

;; Then panic
call platform_panic


global add_symbol_wrapper
add_symbol_wrapper:
push ebp
mov ebp, esp

;; Branch to appropriate stage
mov edx, stage
mov eax, [edx]
cmp eax, 0
je add_symbol_wrapper_stage0
cmp eax, 1
je add_symbol_wrapper_stage1
jmp platform_panic

add_symbol_wrapper_stage0:
;; Call actual add_symbol
push DWORD [ebp+16]
push DWORD [ebp+12]
push DWORD [ebp+8]
call add_symbol
add esp, 12

jmp add_symbol_wrapper_ret

add_symbol_wrapper_stage1:
;; Call find_symbol
push 0
mov edx, esp
push 0
mov ecx, esp
push edx
push ecx
push DWORD [ebp+8]
call find_symbol
add esp, 12
pop edx
pop ecx

;; Check the symbol was found
cmp eax, 0
je platform_panic

;; Check the location matches
cmp edx, [ebp+12]
jne platform_panic

;; Check the arity matches
cmp ecx, [ebp+16]
jne platform_panic

jmp add_symbol_wrapper_ret

add_symbol_wrapper_ret:
pop ebp
ret


global add_symbol_placeholder
add_symbol_placeholder:
push ebp
mov ebp, esp

;; Call find_symbol
push 0
mov edx, esp
push edx
push 0
push DWORD [ebp+8]
call find_symbol
add esp, 12
pop edx

;; Check that the symbol exists if we are not in stage 0
mov ecx, stage
cmp DWORD [ecx], 0
je add_symbol_placeholder_after_assert
cmp eax, 0
je platform_panic

add_symbol_placeholder_after_assert:
;; If the symbol was not found...
cmp eax, 0
jne add_symbol_placeholder_found

;; ...add it, with a fake location
push DWORD [ebp+12]
push 0xffffffff
push DWORD [ebp+8]
call add_symbol
add esp, 12
jmp add_symbol_placeholder_end

add_symbol_placeholder_found:
;; If it was found, check that arity matches
cmp [ebp+12], edx
jne platform_panic

add_symbol_placeholder_end:
pop ebp
ret


global fix_symbol_placeholder
fix_symbol_placeholder:
push ebp
mov ebp, esp
push ebx

;; Call find_symbol
push 0
mov edx, esp
push 0
mov ecx, esp
push edx
push ecx
push DWORD [ebp+8]
call find_symbol
add esp, 12
pop ebx
pop edx

;; Check that the symbol exists if we are not in stage 0
mov ecx, stage
cmp DWORD [ecx], 0
je fix_symbol_placeholder_after_assert
cmp eax, 0
je platform_panic

fix_symbol_placeholder_after_assert:
;; If the symbol was not found...
cmp eax, 0
jne fix_symbol_placeholder_found

;; ...add it, with a fake location
push DWORD [ebp+16]
push DWORD [ebp+12]
push DWORD [ebp+8]
call add_symbol
add esp, 12
jmp fix_symbol_placeholder_end

fix_symbol_placeholder_found:
;; Check that arity matches
cmp [ebp+16], edx
jne platform_panic

;; Check that location matches, or that we are in stage 0 and
;; location is -1
cmp [ebp+12], ebx
je fix_symbol_placeholder_after_second_assert
cmp ebx, 0xffffffff
jne platform_panic
mov ecx, stage
cmp DWORD [ecx], 0
jne platform_panic

fix_symbol_placeholder_after_second_assert:
;; Call get_symbol_idx
push DWORD [ebp+8]
call get_symbol_idx
add esp, 4

;; Assert the index is valid
mov ecx, symbol_num
cmp [ecx], eax
je platform_panic

;; Fix the location value
mov edx, 4
mul edx
mov ecx, symbol_locs_ptr
add eax, [ecx]
mov edx, [ebp+12]
mov [eax], edx

fix_symbol_placeholder_end:
pop ebx
pop ebp
ret


global strcmp
strcmp:
push ebx

;; Load registers
mov eax, [esp+8]
mov ecx, [esp+12]

strcmp_begin_loop:
;; Compare a byte
mov bl, [eax]
mov dl, [ecx]
cmp bl, dl
je strcmp_after_cmp1

;; Return 1 if they differ
;; TODO Differentiate the less than and greater than cases
mov eax, 1
jmp strcmp_end

strcmp_after_cmp1:
;; Check for string termination
cmp bl, 0
jne strcmp_after_cmp2

;; Return 0 if we arrived at the end without finding differences
mov eax, 0
jmp strcmp_end

strcmp_after_cmp2:
;; Increment both pointers and restart
add eax, 1
add ecx, 1
jmp strcmp_begin_loop

strcmp_end:
pop ebx
ret


global strcpy
strcpy:
;; Load registers
mov eax, [esp+4]
mov ecx, [esp+8]

strcpy_begin_loop:
;; Copy a byte
mov dl, [ecx]
mov [eax], dl

;; Return if it was the terminator
cmp dl, 0
je strcpy_end

;; Increment both pointers and restart
add eax, 1
add ecx, 1
jmp strcpy_begin_loop

strcpy_end:
ret


global strlen
strlen:
;; Load register
mov eax, [esp+4]

strlen_begin_loop:
;; Check for termination
mov cl, [eax]
cmp cl, 0
je strlen_end

;; Increment pointer
add eax, 1
jmp strlen_begin_loop

strlen_end:
;; Return the difference between the current and initial address
sub eax, [esp+4]
ret


global find_char
find_char:
;; Load registers
mov eax, [esp+4]
mov dl, [esp+8]

;; Main loop
find_char_loop:
cmp [eax], dl
je find_char_ret
cmp BYTE [eax], 0
je find_char_ret_error
add eax, 1
jmp find_char_loop

;; If we found the target character, return the difference between
;; the current and initial address
find_char_ret:
sub eax, [esp+4]
ret

;; If we found a terminator, return -1
find_char_ret_error:
mov eax, 0xffffffff
ret


SLASH equ 0x2f

AR_BUF_SIZE equ 32

ar_buf:
resb AR_BUF_SIZE


;; void walk_initrd(char *filename, void **begin, void **end)
;; Search the initrd for a file and return the file beginning and
;; end in RAM (undefined behaviour if the file does not exist)
walk_initrd:
push ebp
mov ebp, esp
push esi
push edi

;; Skip the header !<arch>\n (use esi for the current reading
;; position)
mov esi, initrd
add esi, 8

walk_initrd_loop:
;; Copy file name to buffer
push 16
push esi
push ar_buf
call memcpy
add esp, 12

;; Substitute the first slash with a terminator
push SLASH
push ar_buf
call find_char
add esp, 8
cmp eax, 0xffffffff
je platform_panic
add eax, ar_buf
mov BYTE [eax], 0

;; Compare the name with the target name (store in edi)
push ar_buf
push DWORD [ebp+8]
call strcmp
add esp, 8
mov edi, eax

;; Copy file size to the buffer
add esi, 48
push 10
push esi
push ar_buf
call memcpy
add esp, 12

;; Substitute the first space with a terminator
push SPACE
push ar_buf
call find_char
add esp, 8
cmp eax, 0xffffffff
je platform_panic
add eax, ar_buf
mov BYTE [eax], 0

;; Call atoi
push ar_buf
call atoi
add esp, 4

;; Skip file header
add esi, 12

;; If this is the file we want, return things
cmp edi, 0
je walk_initrd_ret_file

;; Skip file content
add esi, eax

;; Realign to 2 bytes
sub esi, 1
or esi, 1
add esi, 1

jmp walk_initrd_loop

walk_initrd_ret_file:
mov edx, [ebp+12]
mov [edx], esi
mov edx, [ebp+16]
add esi, eax
mov [edx], esi

pop edi
pop esi
pop ebp
ret

start:
initrd:


align 512
db 'stop'
align 512
