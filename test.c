
main(argc, argv) {
  int a;
  a = argc + 1;
  int b = argv || a;
  char *c = "{hello}[there](world)";
  b = c + a * a;
  return b;
  int d = 1;
  return d;
}

test(x) {
  int y;
  y = x;
  return x;
}

sum(x, y) {
  int z = x + y;
  return z;
}

hello(bye) {
  bye = 10 + 20;
}