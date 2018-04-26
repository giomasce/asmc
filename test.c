
main(argc, argv) {
  int a;
  a = argc + 1;
  int b = argv || a;
  char *c = "{hello}[there](world)";
  b = c + a * a;
  return b;
}
