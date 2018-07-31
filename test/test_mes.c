
int sub(int x, int y);

int main(int argc, char **argv) {
  int z = sub(argc, 1);
  return z;
}

int sub(int x, int y) {
  return x - y;
}
