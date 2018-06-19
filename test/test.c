
/*#if a * (b + c)
#if a + (b(c,d,e))
#if a + (b((c,d),e))
#if a + b[c]
#endif
#endif
#endif
#endif*/

#define OTHER_TEST 22
TEST_TOK
#define TEST_TOK OTHER_TEST
TEST_TOK
#undef TEST_TOK
TEST_TOK

#define YES
#undef NO

#ifdef NO
not_included();
#ifdef YES
not_included();
#endif
#endif
included();
#ifdef NO
not_included();
#else
included();
#ifndef NO
included();
#else
not_included();
#endif
#endif
#ifdef YES
included();
#else
not_included();
#endif

#include <first.h>
#include \
"other.h"

main(argc, argv) {
  int a1;
  int aA;
  int a_a;
  int a;
  a = glob + argc + 1;
  int b;
  b = argv || a;
  int c;
  c = "{hello}[there](world)";
  if (b != 0) {
    b = c + a * a;
  }
  return b;
  int d;
  d = 1;
  return d;
}

test_if() {
  int x;
  if (x == 0) {
    x = 1;
  } else if (x != 2) {
    x = 3;
  } else {
    x = 2;
  }
}

// C++ comment
int glob2;   \
int glob; /* C comment */
