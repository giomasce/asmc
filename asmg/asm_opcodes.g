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
const OPCODE_M8 88
const OPCODE_M16 92
const OPCODE_M32 96
const OPCODE_RM32M 100
const OPCODE_DEFAULT_32 104
const OPCODE_R32RM32IMM32 108
const OPCODE_RM32R32IMM8 112
const OPCODE_RM32R32CL 116
const OPCODE_RM8CL 120
const OPCODE_RM32CL 124
const OPCODE_ALLOW_CL 128
const SIZEOF_OPCODE 132

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

fun bsf_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands
  $op1
  $op2
  ops vector_size 2 == "bsf_like_handler: error 1" assert_msg ;
  @op1 ops 0 vector_at = ;
  @op2 ops 1 vector_at = ;

  # Determine the operation size
  $size
  if op1 OPERAND_SIZE take 0 != {
    @size op1 OPERAND_SIZE take = ;
    if op2 OPERAND_SIZE take 0 != {
      size op2 OPERAND_SIZE take == "bsf_like_handler: incompatible operand size" assert_msg ;
    }
  } else {
    @size op2 OPERAND_SIZE take = ;
  }
  size 0 != "bsf_like_handler: unspecified operand size" assert_msg ;
  if size 2 == {
    ctx 0x66 asmctx_emit ;
    @size 3 = ;
  }

  # Check operand types
  op1 OPERAND_TYPE take 1 == "bsf_like_handler: destination must be a register" assert_msg ;
  op2 OPERAND_TYPE take 2 != "bsf_like_handler: source cannot be an immediate" assert_msg ;

  $opbytes
  # r32, r/m32
  @opbytes opcode OPCODE_R32RM32 take = ;
  ctx opbytes emit_multibyte ;
  ctx op2 op1 op_to_reg op_to_modrm emit_multibyte ;
  if op2 OPERAND_TYPE take 0 == {
    ctx op2 OPERAND_OFFSET take asmctx_emit32 ;
  }
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
  if opcode OPCODE_FORCE_32 take {
    if size 0 == {
      @size 3 = ;
    }
    size 3 == "sal_like_handler: operand must be 32 bits" assert_msg ;
  }
  # FIXME
  if size 0 == {
    @size 3 = ;
  }
  size 0 != "sal_like_handler: unspecified operand size" assert_msg ;
  if size 2 == {
    ctx 0x66 asmctx_emit ;
    @size 3 = ;
  }

  # Check that the destination is not an immediate
  op1 OPERAND_TYPE take 2 != "sal_like_handler: destination is immediate" assert_msg ;

  $with_cl
  if opcode OPCODE_ALLOW_CL take {
    if op2 OPERAND_TYPE take 2 == {
      @with_cl 0 = ;
    } else {
      op2 OPERAND_TYPE take 1 == "sal_like_handler: count must be immediate or register" assert_msg ;
      op2 OPERAND_SIZE take 1 == "sal_like_handler: count must be 8 bits" assert_msg ;
      op2 OPERAND_REG take 1 == "sal_like_handler: if count is a register, it must be CL" assert_msg ;
      @with_cl 1 = ;
    }
  } else {
    @with_cl 0 = ;
    op2 OPERAND_TYPE take 2 == "sal_like_handler: count must be immediate" assert_msg ;
  }

  $opbytes
  if with_cl {
    if size 1 == {
      # r/m8, cl
      @opbytes opcode OPCODE_RM8CL take = ;
    } else {
      # r/m32, cl
      @opbytes opcode OPCODE_RM32CL take = ;
    }
  } else {
    if size 1 == {
      # r/m8, imm8
      @opbytes opcode OPCODE_RM8IMM8 take = ;
    } else {
      # r/m32, imm8
      @opbytes opcode OPCODE_RM32IMM8 take = ;
    }
  }
  ctx opbytes emit_multibyte ;
  ctx op1 opbytes opcode_to_reg op_to_modrm emit_multibyte ;
  if op1 OPERAND_TYPE take 0 == {
    ctx op1 OPERAND_OFFSET take asmctx_emit32 ;
  }
  if with_cl ! {
    ctx op2 OPERAND_OFFSET take asmctx_emit ;
  }
}

fun lea_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands
  $op1
  $op2
  ops vector_size 2 == "lea_like_handler: error 1" assert_msg ;
  @op1 ops 0 vector_at = ;
  @op2 ops 1 vector_at = ;

  # Determine the operation size
  $size
  @size op1 OPERAND_SIZE take = ;
  size 0 != "lea_like_handler: unspecified operand size" assert_msg ;
  size 3 == "lea_like_handler: operand must be 32 bits" assert_msg ;

  # Check that the the source is an indirect and the destination is a register
  op1 OPERAND_TYPE take 1 == "sal_like_handler: destination must be register" assert_msg ;
  op2 OPERAND_TYPE take 0 == "sal_like_handler: source must be indirect" assert_msg ;

  $opbytes
  @opbytes opcode OPCODE_RM32M take = ;
  ctx opbytes emit_multibyte ;
  ctx op2 op1 op_to_reg op_to_modrm emit_multibyte ;
  ctx op2 OPERAND_OFFSET take asmctx_emit32 ;
}

fun stos_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands (if there are two, the second is ignored)
  $op
  ops vector_size 1 == ops vector_size 2 == || "stos_like_handler: error 1" assert_msg ;
  @op ops 0 vector_at = ;

  # Determine the operation size
  $size
  @size op OPERAND_SIZE take = ;
  if opcode OPCODE_FORCE_8 take {
    if size 0 == {
      @size 1 = ;
    }
    size 1 == "stos_like_handler: operand must be 8 bits" assert_msg ;
  }
  size 0 != "stos_like_handler: unspecified operand size" assert_msg ;

  $opbytes
  if size 1 == {
    # m8
    @opbytes opcode OPCODE_M8 take = ;
  } else {
    if size 2 == {
      # m16
      @opbytes opcode OPCODE_M16 take = ;
    } else {
      # m32
      @opbytes opcode OPCODE_M32 take = ;
    }
  }
  ctx opbytes emit_multibyte ;
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
  size 3 == size 2 == || "movzx_like_handler: destination must be 16 or 32 bits" assert_msg ;
  $src_size
  @src_size op2 OPERAND_SIZE take = ;
  # FIXME
  if src_size 0 == {
    @src_size 1 = ;
  }
  src_size 0 != "movzx_like_handler: unspecified source size" assert_msg ;
  src_size 1 == src_size 2 == || "movzx_like_handler: source must be 8 or 16 bits" assert_msg ;
  src_size 2 == size 2 == && ! "movzx_like_handler: the two operands cannot be 16 bits at the same time" assert_msg ;
  if size 2 == {
    ctx 0x66 asmctx_emit ;
  }

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
  if size 0 == opcode OPCODE_DEFAULT_32 take && {
    @size 3 = ;
  }
  size 0 != "add_like_handler: unspecified operand size" assert_msg ;
  $actual_size
  @actual_size size = ;
  if size 2 == {
    ctx 0x66 asmctx_emit ;
    @size 3 = ;
  }

  # Check that the destination and possibly the source is not an immediate
  op1 OPERAND_TYPE take 2 != "add_like_handler: destination is immediate" assert_msg ;
  if opcode OPCODE_ALLOW_IMM take ! {
    op2 OPERAND_TYPE take 2 != "add_like_handler: source is immediate" assert_msg ;
  }

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
    ctx op2 OPERAND_OFFSET take actual_size emit_size ;
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
  # FIXME
  if size 0 == {
    @size 3 = ;
  }
  size 0 != "jmp_like_handler: unspecified operand size" assert_msg ;
  $actual_size
  @actual_size size = ;
  if size 2 == {
    ctx 0x66 asmctx_emit ;
    @size 3 = ;
  }

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
      if size 1 == {
        @off off current_loc - 1 - = ;
        if ctx ASMCTX_STAGE take 2 == {
          $high
          @high off 0xffffff80 & = ;
          high 0 == high 0xffffff80 == || "jmp_like_handler: relative jump too big" assert_msg ;
        }
      } else {
        @off off current_loc - 4 - = ;
      }
    }
    ctx off actual_size emit_size ;
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

fun shld_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Unpack operands
  $op1
  $op2
  $op3
  ops vector_size 3 == "shld_like_handler: error 1" assert_msg ;
  @op1 ops 0 vector_at = ;
  @op2 ops 1 vector_at = ;
  @op3 ops 2 vector_at = ;

  # Check operands types and sizes
  op1 OPERAND_TYPE take 2 != "shld_like_handler: destination cannot be an immediate" assert_msg ;
  op1 OPERAND_SIZE take 3 == op1 OPERAND_SIZE take 0 == || "shld_like_handler: destination must be 32 bits" assert_msg ;
  op2 OPERAND_TYPE take 1 == "shld_like_handler: source must be a register" assert_msg ;
  op2 OPERAND_SIZE take 3 == op2 OPERAND_SIZE take 0 == || "shld_like_handler: source must be 32 bits" assert_msg ;
  op3 OPERAND_SIZE take 1 == op3 OPERAND_SIZE take 0 == || "shld_like_handler: count must be 8 bits" assert_msg ;

  # Check which variant we are using
  $with_cl
  if op3 OPERAND_TYPE take 2 == {
    @with_cl 0 = ;
  } else {
    op3 OPERAND_TYPE take 1 == "shld_like_handler: count must be immediate or register" assert_msg ;
    op3 OPERAND_REG take 1 == "shld_like_handler: if count is a register, it must be CL" assert_msg ;
    @with_cl 1 = ;
  }

  $opbytes
  if with_cl {
    @opbytes opcode OPCODE_RM32R32CL take = ;
  } else {
    @opbytes opcode OPCODE_RM32R32IMM8 take = ;
  }
  ctx opbytes emit_multibyte ;
  ctx op1 op2 op_to_reg op_to_modrm emit_multibyte ;
  if op1 OPERAND_TYPE take 0 == {
    ctx op1 OPERAND_OFFSET take asmctx_emit32 ;
  }
  if with_cl ! {
    ctx op3 OPERAND_OFFSET take asmctx_emit ;
  }
}

fun imul_like_handler 3 {
  $ctx
  $opcode
  $ops
  @ctx 2 param = ;
  @opcode 1 param = ;
  @ops 0 param = ;

  # Check that the size is acceptable
  ops vector_size 1 >= ops vector_size 3 <= && "imul_like_handler: illegal number of operands" assert_msg ;

  if ops vector_size 1 == {
    # Unpack the operand
    $op
    @op ops 0 vector_at = ;

    # Determine the operation size
    $size
    @size op OPERAND_SIZE take = ;
    # FIXME
    if size 0 == {
      @size 3 = ;
    }
    size 0 != "imul_like_handler: unspecified operand size" assert_msg ;
    size 1 == size 3 == || "imul_like_handler: 16 bits not supported" assert_msg ;

    op OPERAND_TYPE take 2 != "imul_like_handler: operand cannot be immediate" assert_msg ;

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
  } else {
    # Unpack the operands
    $op1
    $op2
    $op3
    @op1 ops 0 vector_at = ;
    @op2 ops 1 vector_at = ;
    $three_ops
    @three_ops 0 = ;

    # If there are two operands, but the second is an immediate, then the first must be repeated twice
    if ops vector_size 2 == op2 OPERAND_TYPE take 2 == && {
      @op3 op2 = ;
      @op2 op1 = ;
      @three_ops 1 = ;
    } else {
      if ops vector_size 3 == {
        @op3 ops 2 vector_at = ;
        @three_ops 1 = ;
      }
    }

    # Some checks
    op1 OPERAND_TYPE take 1 == "imul_like_handler: destination must be a register" assert_msg ;
    op1 OPERAND_SIZE take 3 == op1 OPERAND_SIZE take 0 == || "imul_like_handler: destination must be 32 bits" assert_msg ;
    op2 OPERAND_TYPE take 2 != "imul_like_handler: first souce cannot be an immediate" assert_msg ;
    op2 OPERAND_SIZE take 3 == op2 OPERAND_SIZE take 0 == || "imul_like_handler: first source must be 32 bits" assert_msg ;

    if three_ops ! {
      $opbytes
      # r32, r/m32
      @opbytes opcode OPCODE_R32RM32 take = ;
      ctx opbytes emit_multibyte ;
      ctx op2 op1 op_to_reg op_to_modrm emit_multibyte ;
      if op2 OPERAND_TYPE take 0 == {
        ctx op2 OPERAND_OFFSET take asmctx_emit32 ;
      }
    } else {
      # Missing checks
      op3 OPERAND_TYPE take 2 == "imul_like_handler: second source must be an immediate" assert_msg ;
      op3 OPERAND_SIZE take 3 == op3 OPERAND_SIZE take 0 == || "imul_like_handler: second source must be 32 bits" assert_msg ;
      $opbytes
      # r32, r/m32
      @opbytes opcode OPCODE_R32RM32IMM32 take = ;
      ctx opbytes emit_multibyte ;
      ctx op2 op1 op_to_reg op_to_modrm emit_multibyte ;
      if op2 OPERAND_TYPE take 0 == {
        ctx op2 OPERAND_OFFSET take asmctx_emit32 ;
      }
      ctx op3 OPERAND_OFFSET take asmctx_emit32 ;
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

fun _destroy_opcode_map_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  value free ;
}

fun destroy_opcode_map 1 {
  $opcode_map
  @opcode_map 0 param = ;

  opcode_map @_destroy_opcode_map_closure 0 map_foreach ;
  opcode_map map_destroy ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x05008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x05008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00002801 = ;
  opcode OPCODE_RM32R32 take_addr 0x00002901 = ;
  opcode OPCODE_R8RM8 take_addr 0x00002a01 = ;
  opcode OPCODE_R32RM32 take_addr 0x00002b01 = ;
  opcode_map name opcode map_set ;

  @name "adc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 0 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x02008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x02008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00001001 = ;
  opcode OPCODE_RM32R32 take_addr 0x00001101 = ;
  opcode OPCODE_R8RM8 take_addr 0x00001201 = ;
  opcode OPCODE_R32RM32 take_addr 0x00001301 = ;
  opcode_map name opcode map_set ;

  @name "sbb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 0 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x03008001 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x03008101 = ;
  opcode OPCODE_RM8R8 take_addr 0x00001801 = ;
  opcode OPCODE_RM32R32 take_addr 0x00001901 = ;
  opcode OPCODE_R8RM8 take_addr 0x00001a01 = ;
  opcode OPCODE_R32RM32 take_addr 0x00001b01 = ;
  opcode_map name opcode map_set ;

  @name "mov" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
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
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_DEFAULT_32 take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0000f601 = ;
  opcode OPCODE_RM32IMM32 take_addr 0x0000f701 = ;
  opcode OPCODE_RM8R8 take_addr 0x00008401 = ;
  opcode OPCODE_RM32R32 take_addr 0x00008501 = ;
  opcode OPCODE_R8RM8 take_addr 0x00008401 = ;
  opcode OPCODE_R32RM32 take_addr 0x00008501 = ;
  opcode_map name opcode map_set ;

  @name "xchg" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @add_like_handler = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_DEFAULT_32 take_addr 0 = ;
  opcode OPCODE_RM8R8 take_addr 0x00008601 = ;
  opcode OPCODE_RM32R32 take_addr 0x00008701 = ;
  opcode OPCODE_R8RM8 take_addr 0x00008601 = ;
  opcode OPCODE_R32RM32 take_addr 0x00008701 = ;
  opcode_map name opcode map_set ;

  @name "lea" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @lea_like_handler = ;
  opcode OPCODE_RM32M take_addr 0x00008d01 = ;
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

  @name "jcxz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x00e36702 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "jecxz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000e301 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "loop" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000e201 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "loope" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000e101 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "loopne" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000e001 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "loopnz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000e001 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "loopnzd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM8 take_addr 0x0000e001 = ;
  opcode OPCODE_ALLOW_IMM take_addr 1 = ;
  opcode OPCODE_ALLOW_RM take_addr 0 = ;
  opcode OPCODE_RELATIVE take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
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

  @name "jo" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_IMM32 take_addr 0x00800f02 = ;
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

  @name "seta" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00970f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setae" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00930f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00920f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setbe" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00960f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00920f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "sete" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00940f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setg" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009f0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setge" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009d0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009c0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setle" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009e0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setna" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00960f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnae" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00920f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00930f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setne" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00950f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setng" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009e0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnge" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009c0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009d0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnle" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009f0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setno" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00910f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnp" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009b0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setns" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00990f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setnz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00950f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "seto" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00900f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setp" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009a0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setpe" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009a0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setpo" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x009b0f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "sets" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00980f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "setz" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @jmp_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x00940f02 = ;
  opcode OPCODE_ALLOW_IMM take_addr 0 = ;
  opcode OPCODE_ALLOW_RM take_addr 1 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
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
  opcode OPCODE_ARG_NUM take_addr 0x101 = ;
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
  opcode OPCODE_ARG_NUM take_addr 0x101 = ;
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
  opcode OPCODE_RELATIVE take_addr 0 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "imul" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0xff = ;
  opcode OPCODE_HANDLER take_addr @imul_like_handler = ;
  opcode OPCODE_RM8 take_addr 0x0500f601 = ;
  opcode OPCODE_RM32 take_addr 0x0500f701 = ;
  opcode OPCODE_R32RM32 take_addr 0x00af0f02 = ;
  opcode OPCODE_R32RM32IMM32 take_addr 0x00006901 = ;
  opcode_map name opcode map_set ;

  @name "sal" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0400c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0400c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0400d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0400d301 = ;
  opcode_map name opcode map_set ;

  @name "shl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0400c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0400c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0400d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0400d301 = ;
  opcode_map name opcode map_set ;

  @name "sar" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0700c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0700c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0700d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0700d301 = ;
  opcode_map name opcode map_set ;

  @name "shr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0500c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0500c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0500d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0500d301 = ;
  opcode_map name opcode map_set ;

  @name "rcl" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0200c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0200c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0200d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0200d301 = ;
  opcode_map name opcode map_set ;

  @name "rcr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0300c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0300c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0300d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0300d301 = ;
  opcode_map name opcode map_set ;

  @name "rol" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0000c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0000c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0000d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0000d301 = ;
  opcode_map name opcode map_set ;

  @name "ror" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 1 = ;
  opcode OPCODE_RM8IMM8 take_addr 0x0100c001 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x0100c101 = ;
  opcode OPCODE_RM8CL take_addr 0x0100d201 = ;
  opcode OPCODE_RM32CL take_addr 0x0100d301 = ;
  opcode_map name opcode map_set ;

  @name "bt" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 0 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x04ba0f02 = ;
  opcode_map name opcode map_set ;

  @name "btc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 0 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x07ba0f02 = ;
  opcode_map name opcode map_set ;

  @name "btr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 0 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x06ba0f02 = ;
  opcode_map name opcode map_set ;

  @name "bts" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @sal_like_handler = ;
  opcode OPCODE_FORCE_32 take_addr 0 = ;
  opcode OPCODE_ALLOW_CL take_addr 0 = ;
  opcode OPCODE_RM32IMM8 take_addr 0x05ba0f02 = ;
  opcode_map name opcode map_set ;

  @name "movzx" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @movzx_like_handler = ;
  opcode OPCODE_R32RM8 take_addr 0x00b60f02 = ;
  opcode OPCODE_R32RM16 take_addr 0x00b70f02 = ;
  opcode_map name opcode map_set ;

  @name "movsx" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @movzx_like_handler = ;
  opcode OPCODE_R32RM8 take_addr 0x00be0f02 = ;
  opcode OPCODE_R32RM16 take_addr 0x00bf0f02 = ;
  opcode_map name opcode map_set ;

  @name "ret" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000c301 = ;
  opcode_map name opcode map_set ;

  @name "retn" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000c301 = ;
  opcode_map name opcode map_set ;

  @name "rdpmc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00330f02 = ;
  opcode_map name opcode map_set ;

  @name "rdmsr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00320f02 = ;
  opcode_map name opcode map_set ;

  @name "wrmsr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00300f02 = ;
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

  @name "cdq" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00009801 = ;
  opcode_map name opcode map_set ;

  @name "xlatb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000d701 = ;
  opcode_map name opcode map_set ;

  @name "lodsb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000ac01 = ;
  opcode_map name opcode map_set ;

  @name "lodsw" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00ad6602 = ;
  opcode_map name opcode map_set ;

  @name "lodsd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000ad01 = ;
  opcode_map name opcode map_set ;

  @name "stosb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000aa01 = ;
  opcode_map name opcode map_set ;

  @name "stosw" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00ab6602 = ;
  opcode_map name opcode map_set ;

  @name "stosd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000ab01 = ;
  opcode_map name opcode map_set ;

  @name "scasb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000ae01 = ;
  opcode_map name opcode map_set ;

  @name "scasw" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00af6602 = ;
  opcode_map name opcode map_set ;

  @name "scasd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000af01 = ;
  opcode_map name opcode map_set ;

  @name "movsb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000a401 = ;
  opcode_map name opcode map_set ;

  @name "movsw" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00a56602 = ;
  opcode_map name opcode map_set ;

  @name "movsd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000a401 = ;
  opcode_map name opcode map_set ;

  @name "cmpsb" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000a601 = ;
  opcode_map name opcode map_set ;

  @name "cmpsw" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00a76602 = ;
  opcode_map name opcode map_set ;

  @name "cmpsd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000a701 = ;
  opcode_map name opcode map_set ;

  @name "cbw" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00986602 = ;
  opcode_map name opcode map_set ;

  @name "cwde" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x00009801 = ;
  opcode_map name opcode map_set ;

  @name "salc" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 0 = ;
  opcode OPCODE_HANDLER take_addr @ret_like_handler = ;
  opcode OPCODE_NO_OPERAND take_addr 0x0000d601 = ;
  opcode_map name opcode map_set ;

  @name "xlat" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @stos_like_handler = ;
  opcode OPCODE_M8 take_addr 0x0000d701 = ;
  opcode OPCODE_FORCE_8 take_addr 1 = ;
  opcode_map name opcode map_set ;

  @name "lods" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @stos_like_handler = ;
  opcode OPCODE_M8 take_addr 0x0000ac01 = ;
  opcode OPCODE_M16 take_addr 0x00ad6602 = ;
  opcode OPCODE_M32 take_addr 0x0000ad01 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "stos" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @stos_like_handler = ;
  opcode OPCODE_M8 take_addr 0x0000aa01 = ;
  opcode OPCODE_M16 take_addr 0x00ab6602 = ;
  opcode OPCODE_M32 take_addr 0x0000ab01 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "scas" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 1 = ;
  opcode OPCODE_HANDLER take_addr @stos_like_handler = ;
  opcode OPCODE_M8 take_addr 0x0000ae01 = ;
  opcode OPCODE_M16 take_addr 0x00af6602 = ;
  opcode OPCODE_M32 take_addr 0x0000af01 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "movs" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @stos_like_handler = ;
  opcode OPCODE_M8 take_addr 0x0000a401 = ;
  opcode OPCODE_M16 take_addr 0x00a56602 = ;
  opcode OPCODE_M32 take_addr 0x0000a501 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "cmps" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @stos_like_handler = ;
  opcode OPCODE_M8 take_addr 0x0000a601 = ;
  opcode OPCODE_M16 take_addr 0x00a76602 = ;
  opcode OPCODE_M32 take_addr 0x0000a701 = ;
  opcode OPCODE_FORCE_8 take_addr 0 = ;
  opcode_map name opcode map_set ;

  @name "shld" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 3 = ;
  opcode OPCODE_HANDLER take_addr @shld_like_handler = ;
  opcode OPCODE_RM32R32IMM8 take_addr 0x00a40f02 = ;
  opcode OPCODE_RM32R32CL take_addr 0x00a50f02 = ;
  opcode_map name opcode map_set ;

  @name "shrd" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 3 = ;
  opcode OPCODE_HANDLER take_addr @shld_like_handler = ;
  opcode OPCODE_RM32R32IMM8 take_addr 0x00ac0f02 = ;
  opcode OPCODE_RM32R32CL take_addr 0x00ad0f02 = ;
  opcode_map name opcode map_set ;

  @name "bsf" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @bsf_like_handler = ;
  opcode OPCODE_R32RM32 take_addr 0x00bc0f02 = ;
  opcode_map name opcode map_set ;

  @name "bsr" = ;
  @opcode SIZEOF_OPCODE malloc = ;
  opcode OPCODE_ARG_NUM take_addr 2 = ;
  opcode OPCODE_HANDLER take_addr @bsf_like_handler = ;
  opcode OPCODE_R32RM32 take_addr 0x00bd0f02 = ;
  opcode_map name opcode map_set ;

  opcode_map ret ;
}
