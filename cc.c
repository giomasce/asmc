
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

enum {
  TOK_CALL_OPEN = 0x80,
  TOK_CALL_CLOSED,
  TOK_RO_OPEN,
  TOK_RO_CLOSED,
  TOK_SQ_OPEN,
  TOK_SQ_CLOSED,
  TOK_CU_OPEN,
  TOK_CU_CLOSED,
  TOK_SHL,
  TOK_SHR,
  TOK_LE,
  TOK_GE,
  TOK_EQ,
  TOK_INEQ,
  TOK_AND,
  TOK_OR,
  TOK_DEREF,
  TOK_ADDR,
};

int is_whitespace(char x) {
  return x == ' ' || x == '\t' || x == '\n';
}

void remove_spaces(char *begin, char *end) {
  char *read_buf = begin;
  while (read_buf < end) {
    if (*read_buf == '\0') {
      *begin = '\0';
      return;
    }
    if (is_whitespace(*read_buf)) {
      read_buf++;
    } else {
      *begin = *read_buf;
      begin++;
      read_buf++;
    }
  }
  if (begin < end) {
    *begin = '\0';
  }
}

int find_char(char *s, char *e, char c) {
  char *s2 = s;
  while (1) {
    if (s2 == e) {
      return -1;
    }
    if (*s2 == c) {
      return s2 - s;
    }
    if (*s2 == '\0') {
      return -1;
    }
    s2++;
  }
}

void fix_operands(char *begin, char *end) {
  while (begin + 1 < end) {
    if (*begin == '<' && *(begin+1) == '<') { *begin = TOK_SHL, *(begin+1) = ' '; }
    if (*begin == '>' && *(begin+1) == '>') { *begin = TOK_SHR, *(begin+1) = ' '; }
    if (*begin == '<' && *(begin+1) == '=') { *begin = TOK_LE, *(begin+1) = ' '; }
    if (*begin == '>' && *(begin+1) == '=') { *begin = TOK_GE, *(begin+1) = ' '; }
    if (*begin == '=' && *(begin+1) == '=') { *begin = TOK_EQ, *(begin+1) = ' '; }
    if (*begin == '!' && *(begin+1) == '=') { *begin = TOK_INEQ, *(begin+1) = ' '; }
    if (*begin == '&' && *(begin+1) == '&') { *begin = TOK_AND, *(begin+1) = ' '; }
    if (*begin == '|' && *(begin+1) == '|') { *begin = TOK_OR, *(begin+1) = ' '; }
    begin++;
  }
}

void print(char *begin, char *end) {
  while (begin < end) {
    if (*begin == '\0') {
      break;
    }
    putchar(*begin);
    begin++;
  }
}

void fix_strings(unsigned char *begin, unsigned char *end) {
  int mode = 0;
  while (begin < end) {
    assert(*begin < 0x80);
    if (mode == 0) {
      if (*begin == '\'') {
        mode = 1;
      } else if (*begin == '"') {
        mode = 2;
      }/* else if (*begin == '(') {
        *begin = TOK_RO_OPEN;
      } else if (*begin == ')') {
        *begin = TOK_RO_CLOSED;
      } else if (*begin == '[') {
        *begin = TOK_SQ_OPEN;
      } else if (*begin == ']') {
        *begin = TOK_SQ_CLOSED;
      } else if (*begin == '{') {
        *begin = TOK_CU_OPEN;
      } else if (*begin == '}') {
        *begin = TOK_CU_CLOSED;
      }*/
    } else if (mode == 1) {
      if (*begin == '\'') {
        mode = 0;
      } else {
        assert(*begin >= 0x20);
        *begin += 0x80;
      }
    } else if (mode == 2) {
      if (*begin == '"') {
        mode = 0;
      } else {
        assert(*begin >= 0x20);
        *begin += 0x80;
      }
    }
    begin++;
  }
}

char *find_matching(char open, char closed, char *begin, char *end) {
  int depth = 0;
  while (begin < end) {
    if (*begin == open) {
      depth++;
    } else if (*begin == closed) {
      depth--;
    }
    if (depth == 0) {
      return begin;
    }
    begin++;
  }
}

void compile_statement(char *begin, char *end) {

}

void compile_block(char *begin, char *end) {
  while (1) {
    int pos = find_char(begin, end, ';');
    if (pos == -1) {
      compile_statement(begin, end);
    } else {
      compile_statement(begin, begin+pos);
      begin += pos + 1;
      break;
    }
  }
}

void compile_function(char *def_begin, char *block_begin, char *block_end) {
  compile_block(block_begin+1, block_end-1);
}

void compile_unit(unsigned char *begin, unsigned char *end) {
  unsigned char *def_begin = 0;
  while (begin < end) {
    if (def_begin == 0) {
      if (!is_whitespace(*begin)) {
        def_begin = begin;
      }
    } else {
      if (*begin == '{') {
        unsigned char *res = find_matching('{', '}', begin, end);
        if (res == end) {
          abort();
        }
        compile_function(def_begin, begin, res+1);
        begin = res;
        def_begin = 0;
      }
    }
    begin++;
  }
  assert(def_begin == 0);
}

int main() {
  int fd = open("test.c", O_RDONLY);
  int len = lseek(fd, 0, SEEK_END);
  lseek(fd, 0, SEEK_SET);
  char *src = mmap(0, len, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

  fix_strings(src, src+len);
  fix_operands(src, src+len);
  //remove_spaces(src, src+len);
  print(src, src+len);
  compile_unit(src, src+len);
}
