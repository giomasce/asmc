# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

fun fasm_open 1 {
  $filename
  @filename 0 param = ;

  "FASM: opening file " 1 platform_log ;
  filename 1 platform_log ;
  "\n" 1 platform_log ;

  $fd
  @fd filename vfs_open = ;
  fd ret ;
}

fun fasm_create 1 {
  $filename
  @filename 0 param = ;

  "FASM: creating file " 1 platform_log ;
  filename 1 platform_log ;
  "\n" 1 platform_log ;

  $fd
  @fd filename vfs_open = ;
  if fd 0 == {
    0 ret ;
  }
  fd vfs_truncate ;
  fd ret ;
}

fun fasm_read 3 {
  $fd
  $buf
  $count
  @fd 2 param = ;
  @buf 1 param = ;
  @count 0 param = ;

  $i
  @i 0 = ;
  #"Reading " 1 platform_log ;
  #count itoa 1 platform_log ;
  #" bytes: " 1 platform_log ;
  while i count < {
    $tmp
    @tmp fd vfs_read = ;
    #tmp 1 platform_write_char ;
    if tmp 0xffffffff == {
      0 ret ;
    }
    buf i + tmp =c ;
    @i i 1 + = ;
  }
  #" done!\n" 1 platform_log ;
  1 ret ;
}

fun fasm_write 3 {
  $fd
  $buf
  $count
  @fd 2 param = ;
  @buf 1 param = ;
  @count 0 param = ;

  $i
  @i 0 = ;
  "Writing " 1 platform_log ;
  count itoa 1 platform_log ;
  " bytes: " 1 platform_log ;
  while i count < {
    $tmp
    @tmp buf i + **c =c ;
    fd tmp vfs_write ;
    @i i 1 + = ;
  }
  1 ret ;
}

fun fasm_lseek 3 {
  $fd
  $off
  $whence
  @fd 2 param = ;
  @off 1 param = ;
  @whence 0 param = ;

  $res
  @res fd off whence vfs_seek = ;
  #"Seek to " 1 platform_log ;
  #res itoa 1 platform_log ;
  #"\n" 1 platform_log ;
  res ret ;
}

fun fasm_close 1 {
  $fd
  @fd 0 param = ;

  "FASM: close\n" 1 platform_log ;
  fd vfs_close ;
}

fun fasm_fatal_error 1 {
  $msg
  @msg 0 param = ;

  "FASM FATAL ERROR: " 1 platform_log ;
  msg 1 platform_log ;
  "\n" 1 platform_log ;
}

fun fasm_assembler_error 1 {
  $msg
  @msg 0 param = ;

  "FASM ASSEMBLER ERROR: " 1 platform_log ;
  msg 1 platform_log ;
  "\n" 1 platform_log ;
}

fun fasm_display_block 2 {
  $msg
  $len
  @msg 1 param = ;
  @len 0 param = ;

  $i
  @i 0 = ;
  while i len < {
    msg i + **c 1 platform_write_char ;
    @i i 1 + = ;
  }
}

$instr_num
$ret_instr_enter

fun error_additional_handler 0 {
  "Fault happened after retiring " 1 platform_log ;
  read_ret_instr ret_instr_enter - itoa 1 platform_log ;
  " instructions (according to PMC).\n" 1 platform_log ;
  "Fault happened after executing " 1 platform_log ;
  instr_num itoa 1 platform_log ;
  " instructions (according to single step counter).\n" 1 platform_log ;
}

$dumping
$breakpoint
$breakpoint_instr_num

fun single_step_handler 1 {
  $regs
  @regs 0 param = ;

  $ip
  @ip regs 0x20 + ** = ;

  # "Instruction number " 1 platform_log ;
  # instr_num itoa 1 platform_log ;
  # "\n" 1 platform_log ;

  @instr_num instr_num 1 + = ;

  if breakpoint_instr_num 0 != instr_num breakpoint_instr_num == && {
    @dumping 1 = ;
  }

  if ip breakpoint == {
    @dumping 1 = ;
  }

  if dumping {
    "EAX=" 1 platform_log ;
    regs 0x1c + ** itoa 1 platform_log ;
    ", EBX=" 1 platform_log ;
    regs 0x10 + ** itoa 1 platform_log ;
    ", ECX=" 1 platform_log ;
    regs 0x18 + ** itoa 1 platform_log ;
    ", EDX=" 1 platform_log ;
    regs 0x14 + ** itoa 1 platform_log ;
    ", ESI=" 1 platform_log ;
    regs 0x4 + ** itoa 1 platform_log ;
    ", EDI=" 1 platform_log ;
    regs 0x0 + ** itoa 1 platform_log ;
    ", ESP=" 1 platform_log ;
    regs 0xc + ** itoa 1 platform_log ;
    ", EBP=" 1 platform_log ;
    regs 0x8 + ** itoa 1 platform_log ;
    "\n" 1 platform_log ;

    "Instruction number " 1 platform_log ;
    instr_num itoa 1 platform_log ;
    ": EIP=" 1 platform_log ;
    ip itoa 1 platform_log ;
    ", code: " 1 platform_log ;
    ip 32 dump_mem ;
    "\n\n" 1 platform_log ;
  }
}

fun compile_fasm 0 {
  $filename
  @filename "/disk1/fasm/fasm.asm" = ;

  0x10000 @error_additional_handler = ;

  @ret_instr_enter read_ret_instr = ;
  "Retired instruction counter before compiling fasm: " 1 platform_log ;
  read_ret_instr itoa 1 platform_log ;
  "\n" 1 platform_log ;

  # Compile fasm
  $ctx
  @ctx asmctx_init = ;
  ctx ASMCTX_DEBUG take_addr 0 = ;
  $fd
  @fd filename vfs_open = ;
  fd "compile_fasm: file does not exist" assert_msg ;
  ctx fd asmctx_set_fd ;
  ctx asmctx_compile ;
  fd vfs_close ;

  # Prepare fasm argument list
  $input_file
  $output_file
  @input_file "/disk1/fasm/test.asm" = ;
  @output_file "/ram/test.bin" = ;
  $main_addr
  @main_addr ctx "main" asmctx_get_symbol_addr = ;
  $handles
  @handles 4 vector_init = ;
  handles input_file vector_push_back ;
  handles output_file vector_push_back ;
  handles @malloc vector_push_back ;
  handles @free vector_push_back ;
  handles @platform_setjmp vector_push_back ;
  handles @platform_longjmp vector_push_back ;
  handles @platform_log vector_push_back ;
  handles @fasm_open vector_push_back ;
  handles @fasm_create vector_push_back ;
  handles @fasm_read vector_push_back ;
  handles @fasm_write vector_push_back ;
  handles @fasm_close vector_push_back ;
  handles @fasm_lseek vector_push_back ;
  handles @fasm_fatal_error vector_push_back ;
  handles @fasm_assembler_error vector_push_back ;
  handles @fasm_display_block vector_push_back ;

  @ret_instr_enter read_ret_instr = ;
  "Retired instruction counter before entering fasm: " 1 platform_log ;
  read_ret_instr itoa 1 platform_log ;
  "\n" 1 platform_log ;

  # Enable single stepping
  @instr_num 0 = ;
  @dumping 0 = ;
  #@breakpoint ctx "fix_tables" asmctx_get_symbol_addr = ;
  @breakpoint_instr_num 0 = ;
  0x10010 @single_step_handler = ;
  0x1001c ** \0 ;

  # Run fasm
  $res
  @res handles vector_data main_addr \1 = ;

  # Disable single stepping
  0x10014 0 = ;

  "Retired instruction counter after exiting fasm: " 1 platform_log ;
  read_ret_instr itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "Executed instruction number after exiting fasm: " 1 platform_log ;
  instr_num itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "fasm returned " 1 platform_log ;
  res itoa 1 platform_log ;
  "\n" 1 platform_log ;

  handles vector_destroy ;
  ctx asmctx_destroy ;
}
