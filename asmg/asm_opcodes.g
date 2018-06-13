
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
const SIZEOF_OPCODE 44

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

fun emit_size 3 {
  $ctx
  $data
  $size
  @ctx 2 param = ;
  @data 1 param = ;
  @size 0 param = ;

  if size 1 == {
    ctx data asmctx_emit ;
  } else {
    if size 2 == {
      ctx data asmctx_emit16 ;
    } else {
      if size 3 == {
        ctx data asmctx_emit32 ;
      } else {
        0 "emit_size: invalid size" assert_msg ;
      }
    }
  }
}

fun emit_multibyte 2 {
  $ctx
  $data
  @ctx 1 param = ;
  @data 0 param = ;

  if data 0xff & 1 == {
    ctx data 8 >> asmctx_emit ;
    ret ;
  }
  if data 0xff & 2 == {
    ctx data 8 >> asmctx_emit16 ;
    ret ;
  }
  if data 0xff & 3 == {
    ctx data 8 >> asmctx_emit ;
    ctx data 16 >> asmctx_emit16 ;
    ret ;
  }
  0 "emit_multibyte: error 1" assert_msg ;
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

fun mul_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack the operand
  $op
  ops vector_size 1 == "mul_like_handler: error 1" assert_msg ;
  @op ops 0 vector_at = ;

  # Determine the operation size
  $size
  @size op OPERAND_SIZE take = ;
  size 0 != "mul_like_handler: unspecified operand size" assert_msg ;
  size 1 == size 3 == || "add_like_handler: 16 bits not supported" assert_msg ;

  op OPERAND_TYPE take 2 != "mul_like_handler: operand is immediate" assert_msg ;
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

  @name "mul" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @mul_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0400f601 = ;
  opcode OPCODE_RM32 take_addr 0x0400f701 = ;
  opcode_map name opcode map_set ;

  @_opcode_map opcode_map = ;
}

fun get_opcode_map 0 {
  if _opcode_map ! {
    build_opcode_map ;
  }
  _opcode_map ret ;
}