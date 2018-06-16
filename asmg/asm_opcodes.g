
$_opcode_map

# 0 -> indirect (all fields set), 1 -> register (REG and SIZE set), 2 -> immediate (OFFSET set)
const OPERAND_TYPE 0
# 0 -> unknown, 1 -> 8 bits, 2 -> 16 bits, 3 -> 32 bits
const OPERAND_SIZE 4
const OPERAND_REG 8
const OPERAND_OFFSET 12
const OPERAND_SEGMENT 16
const OPERAND_SCALE 20
const OPERAND_INDEX_REG 24
const SIZEOF_OPERAND 28

const OPCODE_ARG_NUM 0
const OPCODE_HANDLER 4
const OPCODE_RM8IMM8 8
const OPCODE_RM32IMM32 16
const OPCODE_RM8R8 20
const OPCODE_RM32R32 24
const OPCODE_R8RM8 28
const OPCODE_R32RM32 32
const OPCODE_RM8 36
const OPCODE_RM32 40
const OPCODE_IMM8 44
const OPCODE_IMM32 48
const OPCODE_ALLOW_IMM 52
const OPCODE_ALLOW_RM 56
const OPCODE_RELATIVE 60
const OPCODE_FORCE_8 64
const OPCODE_FORCE_32 68
const OPCODE_NO_OPERAND 72
const OPCODE_RM32IMM8 76
const OPCODE_R32RM8 80
const OPCODE_R32RM16 84
const SIZEOF_OPCODE 88

fun assemble_modrm 3 {
  $mod
  $reg
  $rm
  @mod 2 param = ;
  @reg 1 param = ;
  @rm 0 param = ;
  mod 6 << reg 3 << + rm + ret ;
}

fun assemble_sib 3 {
  $scale
  $index
  $base
  @scale 2 param = ;
  @index 1 param = ;
  @base 0 param = ;
  scale 6 << index 3 << + base + ret ;
}

# Least significant nibble: number of bytes (1 or 2)
# Second significant nibble: requires a disp32
# Second significant byte: first byte
# Third significant byte: maybe second byte
fun op_to_modrm 2 {
  $op
  $reg
  @op 1 param = ;
  @reg 0 param = ;

  op OPERAND_TYPE take 2 != "op_to_modrm: cannot call on immediate" assert_msg ;
  if op OPERAND_TYPE take 1 == {
    $modrm
    @modrm 3 reg op OPERAND_REG take assemble_modrm = ;
    modrm 8 << 1 + ret ;
  } else {
    if op OPERAND_INDEX_REG take 8 == {
      if op OPERAND_REG take 8 == {
        $modrm
        @modrm 0 reg 5 assemble_modrm = ;
        modrm 8 << 1 + ret ;
      } else {
        $modrm
        @modrm 2 reg op OPERAND_REG take assemble_modrm = ;
        # Special case for ESP
        if op OPERAND_REG take 4 == {
          $sib
          @sib 0x24 = ;
          sib 16 << modrm 8 << + 2 + ret ;
        } else {
          modrm 8 << 1 + ret ;
        }
      }
    } else {
      # ESP cannot be used for indexing
      op OPERAND_INDEX_REG take 4 != "op_to_modrm: unsupported ESP in index" assert_msg ;
      if op OPERAND_REG take 8 == {
        $modrm
        $sib
        @modrm 0 reg 4 assemble_modrm = ;
        @sib op OPERAND_SCALE take op OPERAND_INDEX_REG take 5 assemble_sib = ;
        sib 16 << modrm 8 << + 2 + ret ;
      } else {
        $modrm
        $sib
        @modrm 2 reg 4 assemble_modrm = ;
        @sib op OPERAND_SCALE take op OPERAND_INDEX_REG take op OPERAND_REG take assemble_sib = ;
        sib 16 << modrm 8 << + 2 + ret ;
      }
    }
  }
}

fun op_to_reg 1 {
  $op
  @op 0 param = ;

  op OPERAND_TYPE take 1 == "op_to_reg: must call on register" assert_msg ;
  op OPERAND_REG take ret ;
}

fun opcode_to_reg 1 {
  $opcode
  @opcode 0 param = ;
  opcode 24 >> ret ;
}

fun sal_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands
  $op1
  $op2
  ops vector_size 2 == "sal_like_handler: error 1" assert_msg ;
  @op1 ops 0 vector_at = ;
  @op2 ops 1 vector_at = ;

  # Determine the operation size
  $size
  @size op1 OPERAND_SIZE take = ;
  size 0 != "sal_like_handler: unspecified operand size" assert_msg ;
  size 1 == size 3 == || "sal_like_handler: 16 bits not supported" assert_msg ;

  # Check that the the source is an immediate and the destination is not an immediate
  op1 OPERAND_TYPE take 2 != "sal_like_handler: destination is immediate" assert_msg ;
  op2 OPERAND_TYPE take 2 == "sal_like_handler: source must be immediate" assert_msg ;

  $opbytes
  if size 1 == {
    # r/m8, imm8
    @opbytes opcode OPCODE_RM8IMM8 take = ;
  } else {
    # r/m32, imm8
    @opbytes opcode OPCODE_RM32IMM8 take = ;
  }
  ctx opbytes emit_multibyte ;
  ctx op1 opbytes opcode_to_reg op_to_modrm emit_multibyte ;
  if op1 OPERAND_TYPE take 0 == {
    ctx op1 OPERAND_OFFSET take asmctx_emit32 ;
  }
  ctx op2 OPERAND_OFFSET take asmctx_emit ;
}

fun movzx_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands
  $op1
  $op2
  ops vector_size 2 == "movzx_like_handler: error 1" assert_msg ;
  @op1 ops 0 vector_at = ;
  @op2 ops 1 vector_at = ;

  # Determine the operation size
  $size
  @size op1 OPERAND_SIZE take = ;
  size 0 != "movzx_like_handler: unspecified destination size" assert_msg ;
  size 3 == "movzx_like_handler: destination must be 32 bits" assert_msg ;
  $src_size
  @src_size op2 OPERAND_SIZE take = ;
  src_size 0 != "movzx_like_handler: unspecified source size" assert_msg ;
  src_size 1 == src_size 2 == || "movzx_like_handler: source must be 8 or 16 bits" assert_msg ;

  # Check that the the source is not an immediate and the destination is a register
  op1 OPERAND_TYPE take 1 == "sal_like_handler: destination is immediate" assert_msg ;
  op2 OPERAND_TYPE take 2 != "sal_like_handler: source must be immediate" assert_msg ;

  $opbytes
  if src_size 1 == {
    # r32, r/m8
    @opbytes opcode OPCODE_R32RM8 take = ;
  } else {
    # r32, r/m16
    @opbytes opcode OPCODE_R32RM16 take = ;
  }
  ctx opbytes emit_multibyte ;
  ctx op2 op1 op_to_reg op_to_modrm emit_multibyte ;
  if op2 OPERAND_TYPE take 0 == {
    ctx op2 OPERAND_OFFSET take asmctx_emit32 ;
  }
}

fun add_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands
  $op1
  $op2
  ops vector_size 2 == "add_like_handler: error 1" assert_msg ;
  @op1 ops 0 vector_at = ;
  @op2 ops 1 vector_at = ;

  # Determine the operation size
  $size
  if op1 OPERAND_SIZE take 0 != {
    @size op1 OPERAND_SIZE take = ;
    if op2 OPERAND_SIZE take 0 != {
      size op2 OPERAND_SIZE take == "add_like_handler: incompatible operand size" assert_msg ;
    }
  } else {
    @size op2 OPERAND_SIZE take = ;
  }
  size 0 != "add_like_handler: unspecified operand size" assert_msg ;
  size 1 == size 3 == || "add_like_handler: 16 bits not supported" assert_msg ;

  # Check that the destination is not an immediate
  op1 OPERAND_TYPE take 2 != "add_like_handler: destination is immediate" assert_msg ;

  if op2 OPERAND_TYPE take 2 == {
    $opbytes
    if size 1 == {
      # r/m8, imm8
      @opbytes opcode OPCODE_RM8IMM8 take = ;
    } else {
      # r/m32, imm32
      @opbytes opcode OPCODE_RM32IMM32 take = ;
    }
    ctx opbytes emit_multibyte ;
    ctx op1 opbytes opcode_to_reg op_to_modrm emit_multibyte ;
    if op1 OPERAND_TYPE take 0 == {
      ctx op1 OPERAND_OFFSET take asmctx_emit32 ;
    }
    ctx op2 OPERAND_OFFSET take size emit_size ;
    ret ;
  }
  if op2 OPERAND_TYPE take 1 == {
    $opbytes
    if size 1 == {
      # r/m8, r8
      @opbytes opcode OPCODE_RM8R8 take = ;
    } else {
      # r/m32, r32
      @opbytes opcode OPCODE_RM32R32 take = ;
    }
    ctx opbytes emit_multibyte ;
    ctx op1 op2 op_to_reg op_to_modrm emit_multibyte ;
    if op1 OPERAND_TYPE take 0 == {
      ctx op1 OPERAND_OFFSET take asmctx_emit32 ;
    }
    ret ;
  }
  if op2 OPERAND_TYPE take 0 == {
    $opbytes
    if size 1 == {
      # r8, r/m 8
      @opbytes opcode OPCODE_R8RM8 take = ;
    } else {
      # r32, r/m32
      @opbytes opcode OPCODE_R32RM32 take = ;
    }
    ctx opbytes emit_multibyte ;
    ctx op2 op1 op_to_reg op_to_modrm emit_multibyte ;
    if op2 OPERAND_TYPE take 0 == {
      ctx op2 OPERAND_OFFSET take asmctx_emit32 ;
    }
    ret ;
  }
  0 "add_like_handler: error 1" assert_msg ;
}

fun jmp_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack the operand
  $op
  ops vector_size 1 == "jmp_like_handler: error 1" assert_msg ;
  @op ops 0 vector_at = ;

  # Determine the operation size
  $size
  @size op OPERAND_SIZE take = ;
  if opcode OPCODE_FORCE_32 take {
    if size 0 == {
      @size 3 = ;
    }
    size 3 == "jmp_like_handler: operand must be 32 bits" assert_msg ;
  }
  if opcode OPCODE_FORCE_8 take {
    if size 0 == {
      @size 1 = ;
    }
    size 1 == "jmp_like_handler: operand must be 8 bits" assert_msg ;
  }
  size 0 != "jmp_like_handler: unspecified operand size" assert_msg ;
  size 1 == size 3 == || "add_like_handler: 16 bits not supported" assert_msg ;

  if opcode OPCODE_ALLOW_IMM take ! {
    op OPERAND_TYPE take 2 != "jmp_like_handler: operand cannot be immediate" assert_msg ;
  }
  if opcode OPCODE_ALLOW_RM take ! {
    op OPERAND_TYPE take 2 == "jmp_like_handler: oprand must be immediate" assert_msg ;
  }

  if op OPERAND_TYPE take 2 == {
    $opbytes
    if size 1 == {
      # imm8
      @opbytes opcode OPCODE_IMM8 take = ;
    } else {
      # imm32
      @opbytes opcode OPCODE_IMM32 take = ;
    }
    ctx opbytes emit_multibyte ;
    $off
    @off op OPERAND_OFFSET take = ;
    if opcode OPCODE_RELATIVE take {
      $current_loc
      @current_loc ctx ASMCTX_CURRENT_LOC take = ;
      @off off current_loc - 4 - = ;
    }
    if size 1 == {
      ctx off asmctx_emit ;
    } else {
      ctx off asmctx_emit32 ;
    }
  } else {
    $opbytes
    if size 1 == {
      # r/m8
      @opbytes opcode OPCODE_RM8 take = ;
    } else {
      # r/m32
      @opbytes opcode OPCODE_RM32 take = ;
    }
    ctx opbytes emit_multibyte ;
    ctx op opbytes opcode_to_reg op_to_modrm emit_multibyte ;
    if op OPERAND_TYPE take 0 == {
      ctx op OPERAND_OFFSET take asmctx_emit32 ;
    }
  }
}

fun ret_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Check there are no operands
  ops vector_size 0 == "jmp_like_handler: error 1" assert_msg ;

  # Just emit the opcode
  ctx opcode OPCODE_NO_OPERAND take emit_multibyte ;
}

fun build_opcode_map 0 {
  $opcode_map
  @opcode_map map_init = ;
  $opcode
  $name

  @name "add" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x00008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x00008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00000001 = ;
  opcode OPCODE_RM32R32 take_addr 0x00000101 = ;
  opcode OPCODE_R8RM8 take_addr 0x00000201 = ;
  opcode OPCODE_R32RM32 take_addr 0x00000301 = ;
  opcode_map name opcode map_set ;

  @name "sub" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x05008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x05008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00002801 = ;
  opcode OPCODE_RM32R32 take_addr 0x00002901 = ;
  opcode OPCODE_R8RM8 take_addr 0x00002a01 = ;
  opcode OPCODE_R32RM32 take_addr 0x00002b01 = ;
  opcode_map name opcode map_set ;

  @name "mov" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0000c601 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x0000c701 = ;
  opcode OPCODE_RM8R8 take_addr 0x00008801 = ;
  opcode OPCODE_RM32R32 take_addr 0x00008901 = ;
  opcode OPCODE_R8RM8 take_addr 0x00008a01 = ;
  opcode OPCODE_R32RM32 take_addr 0x00008b01 = ;
  opcode_map name opcode map_set ;

  @name "cmp" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x07008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x07008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00003801 = ;
  opcode OPCODE_RM32R32 take_addr 0x00003901 = ;
  opcode OPCODE_R8RM8 take_addr 0x00003a01 = ;
  opcode OPCODE_R32RM32 take_addr 0x00003b01 = ;
  opcode_map name opcode map_set ;

  @name "and" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x04008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x04008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00002001 = ;
  opcode OPCODE_RM32R32 take_addr 0x00002101 = ;
  opcode OPCODE_R8RM8 take_addr 0x00002201 = ;
  opcode OPCODE_R32RM32 take_addr 0x00002301 = ;
  opcode_map name opcode map_set ;

  @name "or" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x01008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x01008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00000801 = ;
  opcode OPCODE_RM32R32 take_addr 0x00000901 = ;
  opcode OPCODE_R8RM8 take_addr 0x00000a01 = ;
  opcode OPCODE_R32RM32 take_addr 0x00000b01 = ;
  opcode_map name opcode map_set ;

  @name "xor" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x06008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x06008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00003001 = ;
  opcode OPCODE_RM32R32 take_addr 0x00003101 = ;
  opcode OPCODE_R8RM8 take_addr 0x00003201 = ;
  opcode OPCODE_R32RM32 take_addr 0x00003301 = ;
  opcode_map name opcode map_set ;

  @name "test" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0000f601 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x0000f701 = ;
  opcode OPCODE_RM8R8 take_addr 0x00008401 = ;
  opcode OPCODE_RM32R32 take_addr 0x00008501 = ;
  opcode OPCODE_R8RM8 take_addr 0x00008401 = ;
  opcode OPCODE_R32RM32 take_addr 0x00008501 = ;
  opcode_map name opcode map_set ;

  @name "jmp" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM32 take_addr 0x0400ff01 = ;
  opcode OPCODE_IMM32 take_addr 0x0000e901 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "call" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM32 take_addr 0x0200ff01 = ;
  opcode OPCODE_IMM32 take_addr 0x0000e801 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "ja" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00870f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jae" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00830f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00820f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jbe" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00860f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00820f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "je" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00840f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00840f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jg" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008f0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jge" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008d0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008c0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jle" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008e0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jna" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00860f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnae" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00820f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00830f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnbe" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00870f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00830f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jne" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00850f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jng" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008e0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnge" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008c0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008d0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnle" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008f0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jno" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00810f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnp" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008b0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jns" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00890f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jnz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00850f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jp" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008a0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jpe" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008a0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "jpo" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x008b0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "js" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00880f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "mul" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0400f601 = ;
  opcode OPCODE_RM32 take_addr 0x0400f701 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "imul" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0500f601 = ;
  opcode OPCODE_RM32 take_addr 0x0500f701 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "div" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0600f601 = ;
  opcode OPCODE_RM32 take_addr 0x0600f701 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "idiv" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0700f601 = ;
  opcode OPCODE_RM32 take_addr 0x0700f701 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "not" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0200f601 = ;
  opcode OPCODE_RM32 take_addr 0x0200f701 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "neg" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0300f601 = ;
  opcode OPCODE_RM32 take_addr 0x0300f701 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "inc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0000fe01 = ;
  opcode OPCODE_RM32 take_addr 0x0000ff01 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "dec" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0100fe01 = ;
  opcode OPCODE_RM32 take_addr 0x0100ff01 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "push" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM32 take_addr 0x0600ff01 = ;
  opcode OPCODE_IMM32 take_addr 0x00006801 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_RELATIVE take_addr 0 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "pop" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM32 take_addr 0x00008f01 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode OPCODE_FORCE_32 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "int" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000cd01 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "sal" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0400c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0400c101 = ;
  opcode_map name opcode map_set ;

  @name "shl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0400c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0400c101 = ;
  opcode_map name opcode map_set ;

  @name "sar" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0700c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0700c101 = ;
  opcode_map name opcode map_set ;

  @name "shr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0500c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0500c101 = ;
  opcode_map name opcode map_set ;

  @name "movzx" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @movzx_like_handler = ;
  opcode OPCODE_R32RM8 take_addr 0x00b60f02 = ;
  opcode OPCODE_R32RM16 take_addr 0x00b70f02 = ;
  opcode_map name opcode map_set ;

  @name "ret" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000c301 = ;
  opcode_map name opcode map_set ;

  @name "clc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000f801 = ;
  opcode_map name opcode map_set ;

  @name "cld" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000fc01 = ;
  opcode_map name opcode map_set ;

  @name "cli" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000fa01 = ;
  opcode_map name opcode map_set ;

  @name "cmc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000f501 = ;
  opcode_map name opcode map_set ;

  @name "stc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000f901 = ;
  opcode_map name opcode map_set ;

  @name "std" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000fd01 = ;
  opcode_map name opcode map_set ;

  @name "sti" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000fb01 = ;
  opcode_map name opcode map_set ;

  @_opcode_map opcode_map = ;
}

fun get_opcode_map 0 {
  if _opcode_map ! {
    build_opcode_map ;
  }
  _opcode_map ret ;
}