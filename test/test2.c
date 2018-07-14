
int main(int x, char** y) {
  int i;
  int sum;
  i = 0;
  sum = 0;
  while (i < 200) {
    i = i + 1;
    if (i == 1) continue;
    sum = sum + i;
    int x;
    if (i == 100) break;
  }
  return sum;
}

#ifdef __UNDEF
int test, test2;
unsigned char x, y, z;
char *ptr, arr[8];
short arr2[3];
char *arr3[10];
char *(arr4[10]);
char (*arr5)[10];

void (*main_ptr)(int argc, char *argv[], char*);

// Test from http://www.unixwiz.net/techtips/reading-cdecl.html
char *(*(**foo [0][8])())[];

int main(int other_name, char **);

int main3(int argc, char **argv) {
  char c;
  int x1;
  unsigned int x2;

  c = 4;

  while (0) {
    30;
  }

  if (1) x2;
  else {
    if (2) {
      return 3;
    } else {
      return 4;
    }
  }

  /*2+2;
  2-2;
  2*2;
  2/2;
  2%2;*/

  //2 < (2+2/2);

  2+x1+x;

  int arr[10];

  /*x1;
  c;
  c+x1+x2;
  //"hello";
  main_ptr;*/

  return 20+1+1;
}

int main(int, char**);

int main2() {
  short x;
  return x;
}
#endif
