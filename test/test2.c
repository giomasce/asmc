
int test, test2;
char x, y, z;
char *ptr, arr[8];
short arr2[3];
char *arr3[10];
char *(arr4[10]);
char (*arr5)[10];

void (*main_ptr)(int argc, char *argv[], char*);

// Test from http://www.unixwiz.net/techtips/reading-cdecl.html
char *(*(**foo [0][8])())[];

void main(int other_name, char **);

void main(int argc, char **argv) {
  char c;
  int x1;
  unsigned int x2;
  return;
  int arr[10];

  x1;
  c;
  c+x1+x2;
  "hello";
  main_ptr;
}

