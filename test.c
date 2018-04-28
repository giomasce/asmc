
main(argc, argv) {
  int a;
  a = glob + argc + 1;
  int b;
  b = argv || a;
  int c;
  c = "{hello}[there](world)";
  b = c + a * a;
  return b;
  int d;
  d = 1;
  return d;
}

test(x) {
  int y;
  y = x;
  return x;
}

sum(x, y) {
  int z;
  z = x + y;
  return z;
}

hello(bye) {
  bye = 10 + 20 + 30;
}

empty() {
  return sum(100, 200);
}

in_place_sum(x, y, z) {
  *z = x + y;
  char *z = x + '\n';
  return &y;
}

int glob2;
int glob;
